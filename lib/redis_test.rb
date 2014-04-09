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
      "#{Rails.root}/tmp/cache/#{port}/"
    end

    def pids_path
      "#{Rails.root}/tmp/pids"
    end

    def pidfile
      "#{pids_path}/redis-test-#{port}.pid"
    end

    def start
      FileUtils.mkdir_p cache_path
      FileUtils.mkdir_p pids_path
      redis_options = {
        "daemonize"     => 'yes',
        "pidfile"       => pidfile,
        "port"          => port,
        "timeout"       => 300,
        "save 900"      => 1,
        "save 300"      => 1,
        "save 60"       => 10000,
        "dbfilename"    => db_filename,
        "dir"           => cache_path,
        "loglevel"      => "debug",
        "logfile"       => "stdout",
        "databases"     => 16
      }.map { |k, v| "#{k} #{v}" }.join('\n')
      `echo '#{redis_options}' | redis-server -`


      wait_time_remaining = 5
      begin
        TCPSocket.open("localhost", port)
        success = true
      rescue Exception => e
        if wait_time_remaining > 0
          wait_time_remaining -= 0.1
          sleep 0.1
        else
          raise "Cannot start redis server in 5 seconds. Pinging server yield\n#{e.inspect}"
        end
      end while(!success)
    end

    def stop
      %x{
        cat #{pidfile} | xargs kill -QUIT
        rm -f #{cache_path}#{db_filename}
      }
    end

    def clear
      Redis.current.flushdb
    end
  end
end
