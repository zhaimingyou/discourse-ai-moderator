# frozen_string_literal: true

module Jobs
  class AiModeratePendingReviewables < ::Jobs::Scheduled
    every 5.minutes

    MAX_ENQUEUE_PER_RUN = 20

    def execute(_args)
      return unless SiteSetting.ai_moderator_enabled

      ReviewableQueuedPost
        .pending
        .order(:created_at)
        .limit(MAX_ENQUEUE_PER_RUN)
        .pluck(:id)
        .each { |reviewable_id| Jobs.enqueue(:ai_moderate_reviewable, reviewable_id: reviewable_id) }
    end
  end
end
