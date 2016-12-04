#!/usr/bin/env ruby
require 'yaml'
require 'time'
require 'fileutils'
require 'rubygems'
require 'bundler/setup'

require 'octokit'
require 'faraday-http-cache'
require 'active_support/cache'
require 'active_support/notifications'
require 'pry' if %w(development test).include?(ENV['RUBY_ENV'])

require_relative 'lib/utils'
require_relative 'lib/pull_request_repository'
require_relative 'lib/color_reducer'
require_relative 'lib/adapter/blink1'
require_relative 'lib/adapter/any_bar'

$stdout.sync = true

config_path = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'config.yml')
config = YAML.load_file(config_path)
logger = Utils.make_logger

octokit_config = {
  access_token: config['github']['access_token']
}
if api_endpoint = config['github']['api_endpoint']
  logger.info("Custom API Endpoint: #{api_endpoint}")
  octokit_config[:api_endpoint] = api_endpoint
end

cache_dir = Pathname.new(config['github']['cache_dir'])
cache_dir = File.join(File.expand_path(File.dirname(__FILE__)), cache_dir) unless cache_dir.absolute?
logger.info("Cache directory: #{cache_dir}")
FileUtils.mkdir_p(cache_dir)

cache = ActiveSupport::Cache::FileStore.new(cache_dir)

octokit_client = Octokit::Client.new(octokit_config)
octokit_client.middleware = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, shared_cache: false, store: cache, logger: logger, serializer: Marshal
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
if config['github']['ssl_verify'] == false
  logger.warning('Disabling SSL Certificate Verification')
  octokit_client.connection_options[:ssl] = { verify: false }
end
user = octokit_client.user
logger.info "Logged in as #{user.login}"

repositories_without_ci = config['github']['repositories_without_ci'] || []
repository = PullRequestRepository.new(octokit_client)
last_update_repository = nil
old_color = nil

adapters = [].tap do |adapters|
  if adapter_configs = config['adapters']
    adapter_configs.each do |name, adapter_config|
      next unless adapter_config.delete('enabled') { false }

      klass = case name
              when 'blink1' then Adapter::Blink1
              when 'any_bar' then Adapter::AnyBar
              end
      adapters << klass.new(adapter_config)
    end
  end
end

adapters.each {|a| a.fade_to_color(:off) }

trap('INT') do
  adapters.each {|a| a.fade_to_color(:off) }
  exit
end

loop do
  ratelimit = octokit_client.ratelimit
  logger.debug "Rate Limit: #{ratelimit.remaining}/#{ratelimit.limit} until #{ratelimit.resets_at}"

  if !last_update_repository ||
     (Time.now - last_update_repository) > config['github']['update_repository_interval']
    repository.update_repository!
    last_update_repository = Time.now
  end

  repository.update_pull_requests!

  color = ColorReducer.color(repository, repositories_without_ci)
  if color != old_color
    logger.info("Setting color #{color}")
    adapters.each {|a| a.fade_to_color(color) }
    old_color = color
  end

  logger.debug("Refreshing in #{config['github']['refresh_interval']}s")
  sleep config['github']['refresh_interval']
end
