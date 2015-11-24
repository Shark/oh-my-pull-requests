require 'blink1'

class Blink1Adapter
  def self.fade_to_color(color, luminosity)
    Blink1.open do |blink1|
      if color
        blink1.fade_to_rgb(Blink1Adapter.fade_duration, *Blink1Adapter.color(color, luminosity))
      else
        blink1.fade_to_rgb(Blink1Adapter.fade_duration, *Blink1Adapter.color(:off, luminosity))
      end
    end
  end

  def self.color(color, luminosity)
    colors.fetch(color).map {|e| e * luminosity }
  end

  def self.colors
    {
      red: [255, 0, 0],
      orange: [255, 187, 0],
      green: [0, 255, 0],
      off: [0, 0, 0]
    }
  end

  def self.fade_duration
    1000
  end
end
