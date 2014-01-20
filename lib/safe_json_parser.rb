module SafeJsonParser

  module ClassMethods
    def safe_json(str)
      begin
        return JSON.parse str
      rescue JSON::ParserError => e
        Rails.logger.error "[#{self.name}] Encountered invalid JSON string: #{e.inspect}"
        return nil
      end
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  def safe_json(str)
    self.class.safe_json(str)
  end

end
