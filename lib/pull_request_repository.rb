require_relative 'pull_request'
require_relative 'utils'
require_relative 'github_api'

class PullRequestRepository
  attr_reader :pull_requests

  def initialize(octokit_client)
    @api = GithubApi.new(octokit_client)
    @pull_requests = []
  end

  def update_repository!
    logger.debug('update_repository!')
    @pull_requests = api.pull_requests
  end

  def update_pull_requests!
    logger.debug('update_pull_requests!')

    pull_requests.
    each do |pr|
      pr.state = api.pull_request_state(pr)
    end
  end

  def get(pull_request)
    pull_requests.find {|pr| pr.canonical_name == pull_request.canonical_name }
  end

  private

  def user
    @user ||= octokit_client.user
  end

  def logger
    @logger ||= Utils.make_logger('PullRequestRepository')
  end

  attr_reader :api
end
