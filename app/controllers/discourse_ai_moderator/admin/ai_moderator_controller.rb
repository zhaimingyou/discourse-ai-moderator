# frozen_string_literal: true

module DiscourseAiModerator
  module Admin
    class AiModeratorController < ::Admin::AdminController
      requires_plugin DiscourseAiModerator::PLUGIN_NAME

      LOG_LIMIT = 200

      def logs
        logs = AiModeratorLog.order(created_at: :desc).limit(LOG_LIMIT)
        counts = AiModeratorLog.group(:decision).count

        render json: {
                 enabled: SiteSetting.ai_moderator_enabled,
                 on_uncertain: SiteSetting.ai_moderator_on_uncertain,
                 stats: {
                   approve: counts["approve"] || 0,
                   reject: counts["reject"] || 0,
                   hold: counts["hold"] || 0,
                   error: counts["error"] || 0,
                   total: counts.values.sum,
                 },
                 logs:
                   logs.map do |l|
                     {
                       id: l.id,
                       reviewable_id: l.reviewable_id,
                       decision: l.decision,
                       username: l.username,
                       title: l.title,
                       reason: l.reason,
                       created_at: l.created_at,
                     }
                   end,
               }
      end
    end
  end
end
