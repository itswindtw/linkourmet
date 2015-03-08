require 'resque'
require 'koala'

class LinkGrabber
  @queue = :link_grabber

  def self.perform(access_token)
    graph = Koala::Facebook::API.new(access_token)
    my_links = graph.get_connections("me", "links")
  end
end
