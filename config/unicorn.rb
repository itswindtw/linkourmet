worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 30
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(DB) && DB.disconnect
  Resque.redis.quit
  @resque_pid ||= spawn('env TERM_CHILD=1 QUEUE=* bundle exec rake resque:work')
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  Resque.redis = ENV['REDISCLOUD_URL']
end
