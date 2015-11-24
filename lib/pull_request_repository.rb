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
                    .user_events(user.login, per_page: 100)
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
    prs_to_be_excluded = []
    pull_requests.each do |pr|
      api_pr = octokit_client.pull_request("#{pr.owner}/#{pr.repository}", pr.id)
      pr.head_sha = api_pr.head.sha
      prs_to_be_excluded << pr if api_pr.state == 'open'
    end
    prune! prs_to_be_excluded.map(&:canonical_name)
  end

  def update_states!
    logger.debug('update_states!')
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
                      .select do |pr|
                        if canonical_names.include?(pr.canonical_name)
                          true
                        else
                          logger.debug "Pruning #{pr.canonical_name}"
                          false
                        end
                      end
  end

  def add_pull_request(options)
    new_pull_request = PullRequest.new(options)
    unless get(new_pull_request)
      logger.debug("Found new pull request: #{new_pull_request.canonical_name} at #{new_pull_request.head_sha[0..6]}")
      pull_request = new_pull_request
      pull_requests << new_pull_request
    end

    pull_request
  end

  def logger
    @logger ||= Utils.make_logger('PullRequestRepository')
  end

  attr_reader :octokit_client
end
