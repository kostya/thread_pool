require "../src/thread_pool"
require "digest/md5"

# declare task class, which calculate CPU heavy operation
# it should include ThreadPool::Task and implement execute method
class Task
  include ThreadPool::Task

  getter result : String?

  def initialize(@str : String)
  end

  def execute
    s = @str
    10000.times do
      s = Digest::MD5.hexdigest(s)
    end
    @result = s
  end
end

# run 4 background threads
pool = ThreadPool.new(size: 4, debug: true).run

# create 10 tasks
tasks = Array(Task).new(10) { |i| Task.new(i.to_s) }

# send tasks to background threads, to calculate it in parallel, not blocked
tasks.each { |task| pool << task }

# wait until all tasks done (blocked, concurrency not blocked)
tasks.each { |task| task.wait }

# output tasks results
tasks.each { |task| p task.result }

# stop pool
# pool.stop
