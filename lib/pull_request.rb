require_relative 'utils'

class PullRequest
  attr_reader :owner, :repository, :id, :head_sha, :state, :without_ci

  def initialize(options = {})
    @owner = options.fetch(:owner)
    @repository = options.fetch(:repository)
    @id = options.fetch(:id)
    @head_sha = options.fetch(:head_sha)
    @head_sha_changed = false
    @state = options.fetch(:state) { :unknown }
    @without_ci = options.fetch(:without_ci) { false }
  end

  def canonical_name
    "#{owner}/#{repository}\##{id}"
  end

  def head_sha=(head_sha)
    @head_sha_changed = head_sha != @head_sha
    logger.info("New head_sha #{head_sha[0..6]}") if @head_sha_changed
    @head_sha = head_sha
  end

  def pending?
    !without_ci &&
      (@head_sha_changed ||
      [:unknown, :pending].include?(state))
  end

  def failed?
    !without_ci &&
      [:failure, :error].include?(state)
  end

  def succeeded?
    without_ci ||
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
    logger.info("State #{@state}") if @state != old_state
  end

  def forget_changed!
    @head_sha_changed = false
  end

  private

  def logger
    @logger ||= Utils.make_logger("Pull Request #{canonical_name}")
  end
end
