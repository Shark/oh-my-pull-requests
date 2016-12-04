module Adapter
  class AnyBar
    attr_reader :config

    def initialize(config = {})
      @config = config
      config['host'] ||= 'localhost'
      config['port'] ||= 1738
    end

    def fade_to_color(color)
      client = UDPSocket.new
      client.connect config['host'], config['port']
      client.send color.to_s, 0
    ensure
      client.close if client
    end
  end
end
