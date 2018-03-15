require "./spec_helper"

class SleepTask
  include ThreadPool::Task

  getter result : Float64?

  def initialize(@timeout : Float64)
  end

  def execute
    utime = (@timeout * 1000 * 1000).to_i
    LibC.usleep(utime)
    @result = @timeout
  end
end

describe "test real parallel execution" do
  it "single" do
    should_spend(1.0, 0.5) do
      task = SleepTask.new(1.0)
      POOLS[1].execute(task)
      task.result.should eq 1.0
    end
  end

  it "4 threads" do
    should_spend(1.0, 0.5) do
      tasks = Array.new(4) { SleepTask.new(1.0) }
      tasks.each { |task| POOLS[4] << task }
      tasks.each { |task| task.wait }
      tasks.each { |task| task.result.should eq 1.0 }
    end
  end

  it "8 tasks, 4 threads" do
    should_spend(2.0, 0.5) do
      tasks = Array.new(8) { SleepTask.new(1.0) }
      tasks.each { |task| POOLS[4] << task }
      tasks.each { |task| task.wait }
      tasks.each { |task| task.result.should eq 1.0 }
    end
  end

  it "10 threads" do
    should_spend(1.0, 0.5) do
      tasks = Array.new(10) { SleepTask.new(1.0) }

      tasks.each { |task| POOLS[10] << task }
      tasks.each { |task| task.wait }
      tasks.each { |task| task.result.should eq 1.0 }
    end
  end
end
