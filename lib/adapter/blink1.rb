require 'blink1'

module Adapter
  class Blink1
    attr_reader :config

    def initialize(config = {})
      @config = config
      config['luminosity'] ||= 0.6
      config['fade_duration'] ||= 1000
    end

    def fade_to_color(to_color)
      Blink1.open do |blink1|
        if color
          blink1.fade_to_rgb(config['fade_duration'], *color(to_color, config['luminosity']))
        else
          blink1.fade_to_rgb(config['fade_duration'], *color(:off, config['luminosity']))
        end
      end
    end

    def color(color, luminosity)
      colors.fetch(color).map {|e| e * luminosity }
    end

    def colors
      {
        red: [255, 0, 0],
        orange: [255, 187, 0],
        green: [0, 255, 0],
        off: [0, 0, 0]
      }
    end
  end
end
