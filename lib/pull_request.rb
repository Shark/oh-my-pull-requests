require_relative 'utils'

class PullRequest
  attr_reader :owner, :repository, :id, :head_sha, :state

  def initialize(options = {})
    @owner = options.fetch(:owner)
    @repository = options.fetch(:repository)
    @id = options.fetch(:id)
    @head_sha = options.fetch(:head_sha)
    @head_sha_changed = false
    @state = options.fetch(:state) { :unknown }
  end

  def canonical_name
    "#{owner}/#{repository}\##{id}"
  end

  def head_sha=(head_sha)
    @head_sha_changed = head_sha != @head_sha
    logger.debug("New head_sha #{head_sha} for pull request #{canonical_name}") if @head_sha_changed
    @head_sha = head_sha
  end

  def pending?
    @head_sha_changed ||
      [:unknown, :pending].include?(state)
  end

  def failed?
    [:failure, :error].include?(state)
  end

  def succeeded?
    state == :success
  end

  def states
    [:unknown, :pending, :failure, :error, :success]
  end

  def state=(state)
    old_state = @state
    if states.include?(state)
      @state = state
    else
      @state = :unknown
    end
    logger.debug("Pull request #{canonical_name} state #{@state}") if @state != old_state
  end

  def forget_changed!
    @head_sha_changed = false
  end

  private

  def logger
    @logger ||= Utils.make_logger
  end
end
