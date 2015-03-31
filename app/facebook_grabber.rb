require 'net/http'
require 'resque'
require 'koala'
require 'models'

class FacebookGrabber
  PAGING_LIMIT = 250
  REQUEST_FIELDS = [:status_type, :link, :name, :created_time]
  STATUS_TYPES = [:shared_story]

  @queue = :facebook_grabber

  def self.converted_time(datetime_str)
    DateTime.iso8601(datetime_str).to_time.to_i
  end

  def self.transform_links(my_links)
    # { url: url, title: name, time: timestamp }, ... ] }
    my_links.map do |link|
      {
        url: link['link'],
        title: link['name'],
        time: converted_time(link['created_time'])
      }
    end
  end

  def self.save_links(user_id, my_links)
    links = transform_links(my_links.select { |link| STATUS_TYPES.include?(link['status_type']) })
    user_id = user_id.to_s

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

    my_links = graph.get_connections('me', 'feed', fields: REQUEST_FIELDS, since: cursor)
    while my_links && my_links.length > 0
      save_links(user_id, my_links)
      cursor = converted_time(my_links.first['created_time'])
      my_links = my_links.prev_page(limit: PAGING_LIMIT)
    end

    cursor
  end

  def self.perform_without_cursor(user_id, access_token)
    graph = Koala::Facebook::API.new(access_token)

    my_links = graph.get_connections('me', 'feed', fields: REQUEST_FIELDS)
    cursor = if my_links.empty? then nil else converted_time(my_links.first['created_time']) end
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
