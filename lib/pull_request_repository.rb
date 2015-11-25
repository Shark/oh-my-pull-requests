require_relative 'pull_request'
require_relative 'event_scraper'
require_relative 'utils'

class PullRequestRepository
  attr_reader :pull_requests

  def initialize(octokit_client)
    @octokit_client = octokit_client
    @pull_requests = []
    @event_scraper = EventScraper.new(octokit_client)
  end

  def update_repository!
    logger.debug('update_repository!')

    pull_requests = event_scraper
                    .run
                    .select {|e| e.type == 'PullRequestEvent' && e.actor.login == user.login }
                    .map{|e| e.payload.pull_request }
                    .select{|pr| pr.state == 'open' }
                    .compact
                    .each do |pr|
                      add_pull_request(owner: pr.head.repo.owner.login,
                                       repository: pr.head.repo.name,
                                       id: pr.number,
                                       head_sha: pr.head.sha)
                    end

    true
  end

  def update_pull_requests!
    logger.debug('update_pull_requests!')
    open_pull_requests = []
    pull_requests.each do |pr|
      api_pr = octokit_client.pull_request("#{pr.owner}/#{pr.repository}", pr.id)
      pr.head_sha = api_pr.head.sha
      open_pull_requests << pr if api_pr.state == 'open'
    end
    prune! open_pull_requests.map(&:canonical_name)
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

  def prune!(canonical_names_to_keep)
    @pull_requests = pull_requests
                      .reject do |pr|
                        if !canonical_names_to_keep.include?(pr.canonical_name)
                          logger.debug "Pruning #{pr.canonical_name}"
                          true
                        else
                          false
                        end
                      end
  end

  def add_pull_request(options)
    pull_request = PullRequest.new(options)
    if existing_pull_request = get(pull_request)
      pull_request = existing_pull_request
    else
      logger.debug("Found new pull request: #{pull_request.canonical_name} at #{pull_request.head_sha[0..6]}")
      pull_requests << pull_request
    end

    pull_request
  end

  def logger
    @logger ||= Utils.make_logger('PullRequestRepository')
  end

  def user
    @user ||= octokit_client.user
  end

  attr_reader :octokit_client, :event_scraper
end
