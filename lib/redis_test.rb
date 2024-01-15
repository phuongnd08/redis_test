# frozen_string_literal: true

require 'redis_test/version'
require 'socket'

module RedisTest
  class << self
    def port
      @port ||= (ENV['TEST_REDIS_PORT'] || find_available_port).to_i
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
      @loglevel || 'debug'
    end

    attr_writer :loglevel

    def start(log_to_stdout: false)
      FileUtils.mkdir_p cache_path
      FileUtils.mkdir_p pids_path
      FileUtils.mkdir_p logs_path

      redis_options = {
        'pidfile' => pidfile,
        'port' => port,
        'timeout' => 300,
        'dbfilename' => db_filename,
        'dir' => cache_path,
        'loglevel' => loglevel,
        'databases' => 16
      }

      redis_options['logfile'] = logfile unless log_to_stdout

      redis_options_str = redis_options.map { |k, v| "#{k} #{v}" }.join('\n')
      echo_command = mac? || ubuntu? ? 'echo' : 'echo -e'
      fork do
        system "#{echo_command} '#{redis_options_str}' | redis-server -"
      end

      wait_time_remaining = 5
      begin
        self.socket = TCPSocket.open('localhost', port)
        clear
        @started = true
      rescue Exception => e
        if wait_time_remaining > 0
          wait_time_remaining -= 0.1
          sleep 0.1
        else
          raise "Cannot start redis server in 5 seconds. Pinging server yield\n#{e.inspect}"
        end
      end while(!@started)
    end

    def started?
      @started
    end

    def stop
      if File.file?(pidfile) && File.readable?(pidfile)
        pid = File.read(pidfile).to_i
        if pid > 0
          Process.kill('SIGTERM', pid)
          until (begin
                   Process.getpgid(pid)
                 rescue StandardError
                   nil
                 end).nil?
            sleep 0.01
          end
        end
      end
      FileUtils.rm_f("#{cache_path}#{db_filename}")
      @started = false
    end

    def server_url
      "redis://localhost:#{port}"
    end

    def configure(*options)
      options.flatten.each do |option|
        case option
        when :default
          ENV['REDIS_URL'] = server_url
          Redis.current = Redis.new
          RedisClassy.redis = Redis.current if defined? RedisClassy
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
      socket.puts('flushall')
      socket.gets # wait for redis server to reply with "OK"
    end

    def find_available_port
      server = TCPServer.new('127.0.0.1', 0)
      server.addr[1]
    ensure
      server&.close
    end

    private
    def linux?
      `uname`.downcase.include?("linux")
    end

    def ubuntu?
      return false unless linux?
      return false unless File.exist?('/etc/os-release')
      os_info = File.read('/etc/os-release')
      os_info.include?("ubuntu")
    end

    def mac?
      `uname`.downcase.include?('darwin')
    end

    attr_accessor :socket
  end
end
