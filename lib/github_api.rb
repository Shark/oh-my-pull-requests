class GithubApi
  def initialize(octokit_client)
    @octokit_client = octokit_client
  end

  def pull_requests
    octokit_client.
    search_issues("is:open is:pr involves:#{user.login}").
    items.
    map {|result| result.pull_request.rels[:self].get.data }.
    map do |pr|
      PullRequest.new(owner: pr.head.repo.owner.login,
                      repository: pr.head.repo.name,
                      id: pr.number,
                      head_sha: pr.head.sha)
    end
  end

  def pull_request_state(pull_request)
    head_sha = octokit_client.
               pull_request("#{pull_request.owner}/#{pull_request.repository}", pull_request.id).
               head.
               sha

    octokit_client.
    combined_status("#{pull_request.owner}/#{pull_request.repository}", head_sha).
    state.
    to_sym
  end

  def user
    octokit_client.
    user
  end

  private

  attr_reader :octokit_client
end
