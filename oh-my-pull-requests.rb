#!/usr/bin/env ruby
require 'yaml'
require 'time'
require 'rubygems'
require 'bundler/setup'

require 'octokit'
require 'pry' if %w(development test).include?(ENV['RUBY_ENV'])

require_relative 'lib/utils'
require_relative 'lib/pull_request_repository'
require_relative 'lib/color_reducer'
require_relative 'lib/blink1_adapter'

$stdout.sync = true

config_path = File.join(File.expand_path(File.dirname(__FILE__)), 'config', 'config.yml')
config = YAML.load_file(config_path)
logger = Utils.make_logger

octokit_config = {
  access_token: config['github']['access_token'],
  auto_paginate: true
}
if api_endpoint = config['github']['api_endpoint']
  logger.info("Custom API Endpoint: #{api_endpoint}")
  octokit_config[:api_endpoint] = api_endpoint
end

octokit_client = Octokit::Client.new(octokit_config)
if config['github']['ssl_verify'] == false
  logger.warning('Disabling SSL Certificate Verification')
  octokit_client.connection_options[:ssl] = { verify: false }
end
user = octokit_client.user
logger.info "Logged in as #{user.login}"

repository = PullRequestRepository.new(octokit_client)
last_update_repository = nil
old_color = nil
Blink1Adapter.fade_to_color(:off, config['blink1']['luminosity'])

trap('INT') do
  Blink1Adapter.fade_to_color(:off, config['blink1']['luminosity'])
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
  repository.update_states!
  repository.pull_requests.each(&:forget_changed!)

  color = ColorReducer.color(repository)
  if color != old_color
    logger.info("Setting color #{color}")
    Blink1Adapter.fade_to_color(color, config['blink1']['luminosity'])
    old_color = color
  end

  logger.debug("Refreshing in #{config['github']['refresh_interval']}s")
  sleep config['github']['refresh_interval']
end
