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

def should_spend(timeout, delta = timeout / 5.0)
  t = Time.now
  res = yield
  delta = 0.02 if delta < 0.02
  (Time.now - t).to_f.should be_close(timeout, delta)
  res
end

describe "test real parallel execution" do
  it "single" do
    should_spend(1.0, 0.5) do
      task = SleepTask.new(1.0)
      with_thread_pool(1) do |pool|
        pool.execute(task)
        task.result.should eq 1.0
      end
    end
  end

  it "4 threads" do
    should_spend(1.0, 0.5) do
      tasks = Array.new(4) { SleepTask.new(1.0) }

      with_thread_pool(4) do |pool|
        tasks.each { |task| pool << task }
        tasks.each { |task| task.wait }

        tasks.each { |task| task.result.should eq 1.0 }
      end
    end
  end

  it "8 tasks, 4 threads" do
    should_spend(2.0, 0.5) do
      tasks = Array.new(8) { SleepTask.new(1.0) }

      with_thread_pool(4) do |pool|
        tasks.each { |task| pool << task }
        tasks.each { |task| task.wait }

        tasks.each { |task| task.result.should eq 1.0 }
      end
    end
  end

  it "10 threads" do
    should_spend(1.0, 0.5) do
      tasks = Array.new(10) { SleepTask.new(1.0) }

      with_thread_pool(10) do |pool|
        tasks.each { |task| pool << task }
        tasks.each { |task| task.wait }

        tasks.each { |task| task.result.should eq 1.0 }
      end
    end
  end
end