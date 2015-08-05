require "redis_test/version"

module RedisTest
  class << self
    def port
      (ENV['TEST_REDIS_PORT'] || 9736).to_i
    end

    def db_filename
      "redis-test-#{port}.rdb"
    end

    def cache_path
      "#{Dir.pwd}/tmp/cache/#{port}/"
    end

    def pids_path
      "#{Dir.pwd}/tmp/pids"
    end

    def logs_path
      "#{Dir.pwd}/log"
    end

    def pidfile
      "#{pids_path}/redis-test-#{port}.pid"
    end

    def logfile
      "#{logs_path}/redis.#{port}.log"
    end

    def loglevel
      @loglevel || "debug"
    end

    def loglevel=(level)
      @loglevel = level
    end

    def start
      FileUtils.mkdir_p cache_path
      FileUtils.mkdir_p pids_path
      FileUtils.mkdir_p logs_path

      redis_options = {
        "daemonize"     => 'yes',
        "pidfile"       => pidfile,
        "logfile"       => logfile,
        "port"          => port,
        "timeout"       => 300,
        "dbfilename"    => db_filename,
        "dir"           => cache_path,
        "loglevel"      => loglevel,
        "databases"     => 16
      }.map { |k, v| "#{k} #{v}" }.join('\n')
      `echo '#{redis_options}' | redis-server -`

      wait_time_remaining = 5
      begin
        self.socket = TCPSocket.open("localhost", port)
        clear
        success = true
      rescue Exception => e
        if wait_time_remaining > 0
          wait_time_remaining -= 0.1
          sleep 0.1
        else
          raise "Cannot start redis server in 5 seconds. Pinging server yield\n#{e.inspect}"
        end
      end while(!success)

      ENV['REDIS_URL'] = server_url
    end

    def stop
      pid = File.read(pidfile).to_i
      Process.kill("QUIT", pid)
      FileUtils.rm_f("#{cache_path}#{db_filename}")
    end

    def server_url
      "redis://localhost:#{port}"
    end

    def configure(*options)
      options.flatten.each do |option|
        case option
        when :default
          Redis.current = Redis.new

        when :sidekiq
          Sidekiq.configure_server do |config|
            config.redis = { url: server_url, namespace: 'sidekiq' }
          end

          Sidekiq.configure_client do |config|
            config.redis = { url: server_url, namespace: 'sidekiq' }
          end

        when :ohm
          Ohm.redis = Redic.new(server_url)

        when :resque
          Resque.configure do |config|
            config.redis = "#{server_url}/resque"
          end

        else
          raise "Unable to configure #{option}"
        end
      end
    end

    def clear
      socket.puts("flushall")
      socket.gets # wait for redis server to reply with "OK"
    end

    private
    attr_accessor :socket
  end
end
