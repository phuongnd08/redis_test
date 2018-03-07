require 'spec_helper'

RSpec.describe RedisTest do
  describe '#start' do
    describe "log_to_stdout = false" do
      it "starts fine" do
        expect(RedisTest.started?).to be_falsey
        RedisTest.start
        expect(RedisTest.started?).to be_truthy
        RedisTest.stop
        expect(RedisTest.started?).to be_falsey
      end
    end

    describe "log_to_stdout = true" do
      it "starts fine" do
        expect(RedisTest.started?).to be_falsey
        RedisTest.start(log_to_stdout: true)
        expect(RedisTest.started?).to be_truthy
        RedisTest.stop
        expect(RedisTest.started?).to be_falsey
      end
    end
  end
end
