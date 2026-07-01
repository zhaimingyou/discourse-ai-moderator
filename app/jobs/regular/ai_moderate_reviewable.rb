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

      username = reviewable.target_created_by&.username

      decision, reason =
        begin
          [DiscourseAiModerator::LlmClient.judge(title: title, raw: raw), nil]
        rescue => e
          Rails.logger.warn("[ai-moderator] LLM call failed for reviewable=#{reviewable.id}: #{e.class}: #{e.message}")
          [:uncertain, "LLM error: #{e.message}"]
        end

      # Re-check state: a human may have handled it while we waited on the LLM.
      reviewable.reload
      return unless reviewable.pending?

      case decision
      when :approve
        act(reviewable, :approve_post, "approve", username, title, reason)
      when :reject
        act(reviewable, :reject_post, "reject", username, title, reason)
      else
        handle_uncertain(reviewable, username, title, reason)
      end
    end

    private

    def handle_uncertain(reviewable, username, title, reason)
      case SiteSetting.ai_moderator_on_uncertain
      when "approve"
        act(reviewable, :approve_post, "approve", username, title, reason || "uncertain -> approve")
      when "reject"
        act(reviewable, :reject_post, "reject", username, title, reason || "uncertain -> reject")
      else
        record("hold", reviewable.id, username, title, reason || "uncertain, held for human review")
        Rails.logger.info("[ai-moderator] HOLD reviewable=#{reviewable.id}")
      end
    end

    def act(reviewable, action_id, decision, username, title, reason)
      reviewable.perform(Discourse.system_user, action_id)
      record(decision, reviewable.id, username, title, reason)
      Rails.logger.info("[ai-moderator] #{decision.upcase} reviewable=#{reviewable.id}")
    rescue => e
      Rails.logger.warn("[ai-moderator] perform #{action_id} failed for reviewable=#{reviewable.id}: #{e.class}: #{e.message}")
      record("error", reviewable.id, username, title, "perform #{action_id} failed: #{e.message}")
    end

    def record(decision, reviewable_id, username, title, reason)
      AiModeratorLog.create!(
        reviewable_id: reviewable_id,
        decision: decision,
        username: username,
        title: title.presence,
        reason: reason.to_s[0, 500].presence,
      )
    rescue => e
      Rails.logger.warn("[ai-moderator] failed to record log: #{e.message}")
    end
  end
end
