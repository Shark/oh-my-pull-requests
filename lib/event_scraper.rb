class EventScraper
  def initialize(octokit_client)
    @octokit_client = octokit_client
  end

  def run
    first_event_page = octokit_client
                       .user_events(user.login, per_page: 100)

    events = []
    if first_event_page.any?
      scrape_page_recursive(user, first_event_page, 1, events)
      self.last_event_id = first_event_page.first.id
    end

    events
  end

  private

  def scrape_page_recursive(user, page, page_count, events)
    last_event_id_encountered = false

    page.each do |event|
      last_event_id_encountered = event.id == last_event_id
      break if last_event_id_encountered

      events << event
    end

    if last_event_id_encountered
      logger.debug('Cache hit! Skip processing more events')
    else
      if next_page_rel = octokit_client.last_response.rels[:next]
        logger.debug("Loading event page #{page_count + 1}")
        next_page = octokit_client.get next_page_rel.href
        scrape_page_recursive(user, next_page, page_count + 1, events)
      end
    end
  end

  attr_reader :octokit_client
  attr_accessor :last_event_id

  def user
    @user ||= octokit_client.user
  end

  def logger
    @logger ||= Utils.make_logger('EventScraper')
  end
end
