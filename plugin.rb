# frozen_string_literal: true

# name: discourse-ai-moderator
# about: Auto-moderates queued new-user posts with a local LLM. Listens for reviewables entering the queue, asks the model to APPROVE/REJECT, and acts as the system user.
# version: 0.2.0
# authors: AiSync
# url: https://github.com/zhaimingyou/discourse-ai-moderator

register_asset "stylesheets/ai-moderator.scss"

module ::DiscourseAiModerator
  PLUGIN_NAME = "discourse-ai-moderator"
end

after_initialize do
  require_relative "app/models/ai_moderator_log"
  require_relative "lib/discourse_ai_moderator/llm_client"
  require_relative "app/jobs/regular/ai_moderate_reviewable"
  require_relative "app/controllers/discourse_ai_moderator/admin/ai_moderator_controller"

  # Admin page: Admin -> Plugins -> AI Moderator
  add_admin_route "ai_moderator.admin.title", "discourse-ai-moderator", use_new_show_route: true

  Discourse::Application.routes.append do
    get "/admin/plugins/discourse-ai-moderator/logs" =>
          "discourse_ai_moderator/admin/ai_moderator#logs",
        constraints: AdminConstraint.new
  end

  # Fires (after_commit on create) whenever any reviewable enters the queue.
  on(:reviewable_created) do |reviewable|
    next unless SiteSetting.ai_moderator_enabled
    next unless reviewable.is_a?(ReviewableQueuedPost)
    next unless reviewable.pending?

    Jobs.enqueue(:ai_moderate_reviewable, reviewable_id: reviewable.id)
  end
end
