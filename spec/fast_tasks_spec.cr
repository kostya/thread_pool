require "./spec_helper"

class FastTask
  include ThreadPool::Task

  getter result : Float64?

  def initialize(@timeout : Float64)
  end

  def execute
    @result = @timeout
  end
end

describe "test real parallel execution" do
  (1..10).each do |i|
    it "threaded #{i}" do
      tasks = Array.new(100) { FastTask.new(1.0) }
      should_spend(0.0, 0.5) do
        tasks.each { |task| POOLS[i] << task }
        tasks.each { |task| task.wait }
        tasks.each { |task| task.result.should eq 1.0 }
      end
    end
  end
end
