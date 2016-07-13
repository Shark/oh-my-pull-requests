class ColorReducer
  def self.color(pull_request_repository, repositories_without_ci)
    applicable_pull_requests = pull_request_repository.pull_requests.
                               reject do |pr|
                                 repositories_without_ci.include?("#{pr.owner}/#{pr.repository}")
                               end

    return :green unless applicable_pull_requests.any?

    if applicable_pull_requests.all? {|pr| pr.succeeded? }
      :green
    elsif applicable_pull_requests.any? {|pr| pr.failed? }
      :red
    elsif applicable_pull_requests.any? {|pr| pr.pending? }
      :orange
    end
  end
end
