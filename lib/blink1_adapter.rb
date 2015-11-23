require 'blink1'

class Blink1Adapter
  def self.fade_to_color(color)
    Blink1.open do |blink1|
      if color == :red
        blink1.fade_to_rgb(100, 255, 0, 0)
      elsif color == :orange
        blink1.fade_to_rgb(100, 255, 187, 0)
      elsif color == :green
        blink1.fade_to_rgb(100, 0, 255, 0)
      else
        blink1.fade_to_rgb(100, 0, 0, 0)
      end
    end
  end
end
