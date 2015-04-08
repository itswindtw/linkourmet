require 'resque'
require 'models'
require 'twitter_oauth'
require 'solid_secret'

class TwitterGrabber
  @queue = :twitter_grabber

  def self.converted_time(datetime_str)
    DateTime.parse(datetime_str).to_time.to_i
  end

  def self.save_links(user_id, links)
    user_id = user_id.to_s

    return if links.empty?

    uri = URI("#{API_ENDPOINT}/sendLink")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = { user: user_id, links: links }.to_json
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    puts "Req #{req.body}"
    puts "Resp #{res.code} #{res.message}: #{res.body}"
  end

  def self.perform_timeline(user_id, client, since_id = nil)
    # from most-recent to least-recent (use max_id and since_id)
    cursor = nil
    params = {
      count: 200,
      trim_user: true,
      exclude_replies: true
    }
    params[:since_id] = since_id if since_id

    tweets = client.user_timeline(params)
    cursor = tweets.first['id_str'] unless tweets.empty?

    until tweets.empty?
      tweets_with_urls = tweets.reject { |tweet| tweet['entities']['urls'].empty? }

      my_links = tweets_with_urls.flat_map do |tweet|
        tweet['entities']['urls'].map do |u|
          {
            url: u['expanded_url'],
            title: u['display_url'],
            time: converted_time(tweet['created_at'])
          }
        end
      end

      save_links(user_id, my_links)

      params[:max_id] = (tweets.last['id_str'].to_i-1).to_s
      tweets = client.user_timeline(params)
    end

    cursor
  end

  def self.perform(user_id, token, token_secret)
    user = User[user_id]
    cursor = user.twitter_service.cursor
    new_cursor = nil

    client = TwitterOAuth::Client.new(
      consumer_key: SolidSecret::TWITTER_CONSUMER_KEY,
      consumer_secret: SolidSecret::TWITTER_CONSUMER_SECRET,
      token: user.twitter_service.access_token,
      secret: user.twitter_service.access_token_secret
    )

    begin
      new_cursor = if cursor
        perform_timeline(user_id, client, cursor)
      else
        perform_timeline(user_id, client)
      end
    ensure
      user.decrement_active_workers!
      user.twitter_service.update(cursor: new_cursor)
    end
  end
end
