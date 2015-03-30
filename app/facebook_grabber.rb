require 'net/http'
require 'resque'
require 'koala'
require 'models'

class FacebookGrabber
  PAGING_LIMIT = 100
  LINK_FIELDS = [:link, :name, :created_time]

  @queue = :facebook_grabber

  def self.transform_links(my_links)
    # { url: url, title: name, time: timestamp }, ... ] }
    my_links.map do |link|
      {
        url: link['link'],
        title: link['name'],
        time: DateTime.iso8601(link['created_time']).to_time.to_i
      }
    end
  end

  def self.save_links(user_id, my_links)
    links = transform_links(my_links)

    uri = URI("#{API_ENDPOINT}/sendLink")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = { user: user_id, links: links }.to_json
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    puts "Resp #{res.code} #{res.message}: #{res.body}"
  end

  def self.perform_with_cursor(user_id, access_token, cursor)
    graph = Koala::Facebook::API.new(access_token)

    my_links = graph.get_connections('me', 'links', fields: LINK_FIELDS, before: cursor)
    while my_links && my_links.length > 0
      save_links(user_id, my_links)
      cursor = my_links.paging['cursors']['before']
      my_links = my_links.prev_page(limit: PAGING_LIMIT)
    end

    cursor
  end

  def self.perform_without_cursor(user_id, access_token)
    graph = Koala::Facebook::API.new(access_token)

    my_links = graph.get_connections('me', 'links', fields: LINK_FIELDS)
    cursor = my_links.paging['cursors']['before'] if my_links.paging
    while my_links && my_links.length > 0
      save_links(user_id, my_links)
      my_links = my_links.next_page(limit: PAGING_LIMIT)
    end

    cursor
  end

  def self.perform(user_id, access_token)
    user = User[user_id]
    cursor = user.facebook_service.cursor

    # Two cases here: First time; Otherwise(having cursor)
    new_cursor = if cursor
      perform_with_cursor(user_id, access_token, cursor)
    else
      perform_without_cursor(user_id, access_token)
    end

    user.decrement_active_workers!
    user.facebook_service.update(cursor: new_cursor)
    true
  end
end
