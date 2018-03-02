# RedisTest

This is a very simple gem to help start/stop an instance of redis server
during test.

There is different option out there like fakeredis but I dislike
fakeredis approach as it require the gem to re-implement all the
functionality of redis, so every time redis is upgrading, the gem
need to be updated as well.

My approach is very simple, and may be already widely used:
Start a redis server on port 9736 (can be
customized by setting `ENV['TEST_REDIS_PORT']`) and simply change your
config so your redis client will connect there during test instead.

I just try to package it in a convenient way so I don't have to repeat
it for every project I use.

## Installation

Add this line to your application's Gemfile:

    gem 'redis_test'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_test

## Usage

You can use it with RSpec by putting this block under your spec/support:

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    RedisTest.start(log_to_stdout: true)
    # if log_to_stdout ommited it will logs to file
    RedisTest.configure(:default, :sidekiq)
    # RedisTest provide common configuration for :default (set
    # Redis.current), :sidekiq, :ohm (set Ohm.redis) and :resque.
  end

  config.after(:each) do
    RedisTest.clear
    # notice that will flush the Redis db, so it's less
    # desirable to put that in a config.before(:each) since it may clean any
    # data that you try to put in redis prior to that
  end

  config.after(:suite) do
    RedisTest.stop
  end
end
```

Or with Cucumber by putting this block under your features/support:

```ruby
RedisTest.start # start this when cucumber load
RedisTest.configure(:default, :sidekiq)
# available option: :default, :sidekiq, :ohm, :resque

After do
  RedisTest.clear
  # clear redis after every scenario to avoid interference
end

at_exit do
  RedisTest.stop
end

```

There is a `RedisTest.server_url` (which by default return
`"redis://localhost:9736"`) that you can use to configure your custom tool
that use Redis

## For Parallel Testing
You can start multiple instances of redis in parallel by rotating
`ENV['TEST_REDIS_PORT']`

## Log information
All log will be available at log/redis.PORT.log
The default log level is `debug`, which will dump a lot of log.
Customize your loglevel by setting RedisTest.loglevel to `debug`, `verbose`,
`notice` or `warning`. See https://raw.githubusercontent.com/antirez/redis/2.8/redis.conf for explanation regarding redis log level
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
