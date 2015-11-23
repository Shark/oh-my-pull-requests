require_relative 'pull_request'
require_relative 'utils'

class PullRequestRepository
  attr_reader :pull_requests

  def initialize(octokit_client)
    @octokit_client = octokit_client
    @pull_requests = []
  end

  def update_repository!
    logger.debug('update_repository!')
    user = octokit_client.user
    api_prs = octokit_client
                    .user_events(user.login)
                    .select {|event| event.type == 'PullRequestEvent' && event.actor.login == user.login }
                    .map {|event| event.payload.pull_request }
                    .select {|pr| pr.state == 'open' }
                    .compact

    canonical_names = []
    api_prs.each do |pr|
      pull_request = add_pull_request(owner: pr.head.repo.owner.login,
                                      repository: pr.head.repo.name,
                                      id: pr.number,
                                      head_sha: pr.head.sha)
      canonical_names << pull_request.canonical_name
    end
    prune! canonical_names

    true
  end

  def update_pull_requests!
    logger.debug('update_pull_requests!')
    pull_requests
      .select(&:pending?)
      .each do |pr|
        logger.debug("Updating pull request #{pr.canonical_name}")
        status = octokit_client.combined_status("#{pr.owner}/#{pr.repository}", pr.head_sha)
        pr.state = status.state.to_sym
      end
  end

  def get(pull_request)
    pull_requests.find {|pr| pr.canonical_name == pull_request.canonical_name }
  end

  private

  def prune!(canonical_names)
    @pull_requests = pull_requests
                      .select {|pr| canonical_names.include?(pr.canonical_name)}
  end

  def add_pull_request(options)
    new_pull_request = PullRequest.new(options)
    if pull_request = get(new_pull_request)
      pull_request.head_sha = new_pull_request.head_sha
    else
      logger.debug("Found new pull request: #{new_pull_request.canonical_name}")
      pull_request = new_pull_request
      pull_requests << new_pull_request
    end

    pull_request
  end

  def logger
    @logger ||= Utils.make_logger
  end

  attr_reader :octokit_client
end
