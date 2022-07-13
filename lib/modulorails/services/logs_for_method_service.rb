# @author Matthieu CIAPPARA <ciappa_m@modulotech.fr>
# A service to write formatted debug logs from a method.
class Modulorails::LogsForMethodService < Modulorails::BaseService

  # @param method [String] The name of the calling method
  # @param message [String,#to_json] The body of the log.
  # @param tags [Array<String,#to_tag>] A list of tags to prefix the log.
  def initialize(method:, message:, tags: [])
    super()
    @method  = method
    @message = message
    @tags    = tags
  end

  # Write a formatted debug log using given initialization parameters
  def call
    # Map the tags (either objects responding to #to_tag or strings) to prefix the log body
    tag_strings = @tags.map do |tag|
      tag.respond_to?(:to_tag) ? "[#{tag.to_tag}]" : "[#{tag}]"
    end

    # If the message respond_to #to_json (and is not a String), use it.
    @message = jsonify if !@message.is_a?(String) && @message.respond_to?(:to_json)

    # Join the tags
    tag_string = tag_strings.join

    # Split on newlines to avoid a log of a thousand columns and for each line, prefix the tags
    # and log it as debug.
    @message.split("\n").each do |line|
      msg = "#{tag_string}[#{@method}] #{line}"

      Rails.logger.debug(msg)
    end
  end

  private

  def jsonify
    @message.to_json
  end

end
