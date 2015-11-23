class ColorReducer
  def self.color(pull_request_repository)
    if pull_request_repository.pull_requests.all? {|pr| pr.succeeded? }
      :green
    elsif pull_request_repository.pull_requests.any? {|pr| pr.failed? }
      :red
    elsif pull_request_repository.pull_requests.any? {|pr| pr.pending? }
      :orange
    else
      nil
    end
  end
end
