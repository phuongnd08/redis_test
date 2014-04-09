# RedisTest

This is a very simple gem to help start/stop an instance of redis server
during test.

There is different option out there like fakeredis but I dislike this
approach as it require the gem to re-implement all the functionality of
redis.

My approach is very simple, and may be already widely used:
Start a redis server on port 9736 (can be
customized by setting ENV['TEST_REDIS_PORT']) and simply change your
config so your redis client will connect there during test instead.

I just try to package it in a convenient way so I don't have to repeat
it for every project I use.

## Installation

Add this line to your application's Gemfile:

    gem 'redis-test', require: 'redis/test'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-test

## Usage

You can use it with RSpec by putting this block under your spec/support:

```
RSpec.configure do |config|
  config.before(:suite) do
    RedisTest.start
    RedisTest.configure(:default, :sidekiq, :ohm)
    # RedisTest provide common configuration for :default (set
    # Redis.current), :sidekiq, :ohm and :resque.
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

```
RedisTest.start # start this when cucumber load
RedisTest.configure(:default, :sidekiq, :ohm)
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
"redis://localhost:9763") so you can use to configure your custom tool
that use Redis

## For Parallel Testing
You can start multiple instances of redis in parallel by rotating
ENV['TEST_REDIS_PORT']

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
