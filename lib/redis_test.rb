require "redis_test/version"

module RedisTest
  PIDS_PATH = "#{Rails.root}/tmp/pids"
  REDIS_PID = "#{PIDS_PATH}/redis-test.pid"
  REDIS_CACHE_PATH = "#{Rails.root}/tmp/cache/"
  REDIS_DB_FILENAME = "#{Rails.root}/tmp/dump.rdb"

  class << self
    def redis_port
      (ENV['TEST_REDIS_PORT'] || 9736).to_i
    end

    def start
      FileUtils.mkdir_p REDIS_CACHE_PATH
      FileUtils.mkdir_p PIDS_PATH
      redis_options = {
        "daemonize"     => 'yes',
        "pidfile"       => REDIS_PID,
        "port"          => redis_port,
        "timeout"       => 300,
        "save 900"      => 1,
        "save 300"      => 1,
        "save 60"       => 10000,
        "dbfilename"    => REDIS_DB_FILENAME,
        "dir"           => REDIS_CACHE_PATH,
        "loglevel"      => "debug",
        "logfile"       => "stdout",
        "databases"     => 16
      }.map { |k, v| "#{k} #{v}" }.join('\n')
      `echo '#{redis_options}' | redis-server -`


      wait_time_remaining = 5
      begin
        TCPSocket.open("localhost", redis_port)
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
        cat #{REDIS_PID} | xargs kill -QUIT
        rm -f #{REDIS_CACHE_PATH}#{REDIS_DB_FILENAME}
      }
    end

    def clear
      Redis.current.flushdb
    end
  end
end
