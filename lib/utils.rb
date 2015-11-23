require 'logger'

class Utils
  def self.make_logger
    Logger.new($stdout).tap do |logger|
      logger.progname = 'oh-my-pull-requests'

      unless %w(development test).include? ENV['RUBY_ENV']
        logger.level = Logger::INFO
      end
    end
  end
end
