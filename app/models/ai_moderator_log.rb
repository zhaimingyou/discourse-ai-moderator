# frozen_string_literal: true

class AiModeratorLog < ActiveRecord::Base
  DECISIONS = %w[approve reject hold error].freeze

  validates :decision, presence: true
end
