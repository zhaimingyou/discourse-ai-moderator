# frozen_string_literal: true

# name: discourse-ai-moderator
# about: Auto-moderates queued new-user posts with a local LLM. Listens for reviewables entering the queue, asks the model to APPROVE/REJECT, and acts as the system user.
# version: 0.1.0
# authors: AiSync
# url: https://github.com/AiSync/discourse-ai-moderator

enabled_site_setting :ai_moderator_enabled

module ::DiscourseAiModerator
  PLUGIN_NAME = "discourse-ai-moderator"
end

after_initialize do
  require_relative "lib/discourse_ai_moderator/llm_client"
  require_relative "app/jobs/regular/ai_moderate_reviewable"

  # Fires (after_commit on create) whenever any reviewable enters the queue.
  on(:reviewable_created) do |reviewable|
    next unless SiteSetting.ai_moderator_enabled
    next unless reviewable.is_a?(ReviewableQueuedPost)
    next unless reviewable.pending?

    Jobs.enqueue(:ai_moderate_reviewable, reviewable_id: reviewable.id)
  end
end
