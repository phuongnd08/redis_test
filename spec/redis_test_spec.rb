require 'spec_helper'

RSpec.describe RedisTest do
  describe '#start' do
    describe "log_to_stdout = false" do
      it "starts fine" do
        RedisTest.start
        RedisTest.stop
      end
    end
  end

  describe '#start' do
    describe "log_to_stdout = true" do
      it "starts fine" do
        RedisTest.start(log_to_stdout: false)
        RedisTest.stop
      end
    end
  end
end
