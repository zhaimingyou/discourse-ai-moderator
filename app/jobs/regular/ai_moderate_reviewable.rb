# frozen_string_literal: true

module Jobs
  class AiModerateReviewable < ::Jobs::Base
    sidekiq_options queue: "low", retry: 3

    def execute(args)
      return unless SiteSetting.ai_moderator_enabled

      reviewable = ReviewableQueuedPost.find_by(id: args[:reviewable_id])
      return if reviewable.blank?
      return unless reviewable.pending?

      title = reviewable.payload&.[]("title").to_s
      raw = reviewable.payload&.[]("raw").to_s
      return if raw.blank?

      decision =
        begin
          DiscourseAiModerator::LlmClient.judge(title: title, raw: raw)
        rescue => e
          Rails.logger.warn("[ai-moderator] LLM call failed for reviewable=#{reviewable.id}: #{e.class}: #{e.message}")
          :uncertain
        end

      # Re-check state: it may have been handled by a human while we waited on the LLM.
      reviewable.reload
      return unless reviewable.pending?

      case decision
      when :approve
        act(reviewable, :approve_post, "APPROVE")
      when :reject
        act(reviewable, :reject_post, "REJECT")
      else
        handle_uncertain(reviewable)
      end
    end

    private

    def handle_uncertain(reviewable)
      case SiteSetting.ai_moderator_on_uncertain
      when "approve"
        act(reviewable, :approve_post, "UNCERTAIN->APPROVE")
      when "reject"
        act(reviewable, :reject_post, "UNCERTAIN->REJECT")
      else
        Rails.logger.info("[ai-moderator] HOLD reviewable=#{reviewable.id} (left for human review)")
      end
    end

    def act(reviewable, action_id, label)
      reviewable.perform(Discourse.system_user, action_id)
      Rails.logger.info("[ai-moderator] #{label} reviewable=#{reviewable.id}")
    rescue => e
      Rails.logger.warn("[ai-moderator] perform #{action_id} failed for reviewable=#{reviewable.id}: #{e.class}: #{e.message}")
    end
  end
end
