# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module DiscourseAiModerator
  class LlmClient
    class Error < StandardError; end

    DEFAULT_BASE_URL = "http://172.17.0.1:19119/v1"
    DEFAULT_MODEL = "Qwen3.6-35B-A3B-DSV4Pro-Distill-MTP-Q5_K_M-imatrix.gguf"

    # Returns :approve, :reject, or :uncertain
    def self.judge(title:, raw:)
      answer = request_chat(build_user_content(title, raw))
      normalize(answer)
    end

    def self.build_user_content(title, raw)
      limit = SiteSetting.ai_moderator_max_content_chars
      parts = []
      parts << "标题: #{title}" if title.present?
      parts << "正文:\n#{raw.to_s[0, limit]}"
      parts.join("\n")
    end

    def self.request_chat(user_content)
      api_key = SiteSetting.ai_moderator_llm_key
      base_url = (SiteSetting.ai_moderator_llm_url.presence || DEFAULT_BASE_URL).chomp("/")
      model = SiteSetting.ai_moderator_llm_model.presence || DEFAULT_MODEL

      endpoint = base_url.include?("/v1") ? "" : "/v1"
      uri = URI("#{base_url}#{endpoint}/chat/completions")

      http = FinalDestination::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.read_timeout = SiteSetting.ai_moderator_request_timeout
      http.open_timeout = 15

      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["Authorization"] = "Bearer #{api_key}" if api_key.present?

      req.body = {
        model: model,
        messages: [
          { role: "system", content: SiteSetting.ai_moderator_system_prompt },
          { role: "user", content: user_content },
        ],
        temperature: 0,
        max_tokens: 32,
        chat_template_kwargs: { enable_thinking: false },
      }.to_json

      resp = http.request(req)
      resp.value

      data = JSON.parse(resp.body)
      raw = data.dig("choices", 0, "message", "content").to_s
      raw = data.dig("choices", 0, "message", "reasoning_content").to_s if raw.blank?
      raise Error.new("empty LLM response") if raw.blank?
      raw
    end

    def self.normalize(answer)
      text = answer.to_s.upcase
      approve = text.include?("APPROVE")
      reject = text.include?("REJECT")

      return :uncertain if approve && reject
      return :approve if approve
      return :reject if reject
      :uncertain
    end
  end
end
