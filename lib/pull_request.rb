require_relative 'utils'

class PullRequest
  attr_reader :owner, :repository, :id, :head_sha, :state

  def initialize(options = {})
    @owner = options.fetch(:owner)
    @repository = options.fetch(:repository)
    @id = options.fetch(:id)
    @head_sha = options.fetch(:head_sha)
    @state = options.fetch(:state) { :unknown }
  end

  def canonical_name
    "#{owner}/#{repository}\##{id}"
  end

  def head_sha=(head_sha)
    logger.info("New head_sha #{head_sha[0..6]}") if head_sha != @head_sha
    @head_sha = head_sha
  end

  def pending?
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
    logger.info("State #{@state}") if @state != old_state
  end

  private

  def logger
    @logger ||= Utils.make_logger("Pull Request #{canonical_name}")
  end
end
