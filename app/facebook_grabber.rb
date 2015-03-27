require 'net/http'
require 'resque'
require 'koala'
require 'models'

class FacebookGrabber
  API_ENDPOINT = "http://54.186.129.251:3000"
  PAGING_LIMIT = 100
  LINK_FIELDS = [:link, :name, :created_time]

  @queue = :facebook_grabber

  def self.saveLinks(user_id, links)
    # { url: url, title: name, time: timestamp }, ... ] }
    my_links = links.map do |link|
      {
        url: link['link'],
        title: link['name'],
        time: DateTime.iso8601(link['created_time']).to_time.to_i
      }
    end

    uri = URI("#{API_ENDPOINT}/sendLink")
    req = Net::HTTP::Post.new(uri, initheader = { 'Content-Type' =>'application/json' })
    req.body = { user: user_id, links: my_links }.to_json
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    puts "Resp #{res.code} #{res.message}: #{res.body}"
  end

  def self.perform(user_id, access_token)
    user = User[user_id]
    graph = Koala::Facebook::API.new(access_token)

    cursor = user.facebook_service.cursor

    # Two cases here: First time; Otherwise(having cursor)
    if cursor
      my_links = graph.get_connections('me', 'links', fields: LINK_FIELDS, before: cursor)
      while my_links and my_links.length > 0
        saveLinks(user_id, my_links)
        cursor = my_links.paging['cursors']['before']
        my_links = my_links.prev_page(limit: PAGING_LIMIT)
      end
    else
      my_links = graph.get_connections('me', 'links', fields: LINK_FIELDS)
      cursor = my_links.paging['cursors']['before'] if my_links.paging
      while my_links and my_links.length > 0
        saveLinks(user_id, my_links)
        my_links = my_links.next_page(limit: PAGING_LIMIT)
      end
    end

    user.decrement_active_workers!
    user.facebook_service.update(cursor: cursor)
    true
  end
end
