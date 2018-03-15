require "../src/thread_pool"

class Task
  include ThreadPool::Task

  getter result : String?

  def initialize(@str : String)
  end

  def execute
    LibC.usleep(1000) # 1/1000 s
    @result = @str
  end
end

# run 4 background threads
pool = ThreadPool.new(size: 4, debug: true).run

task = Task.new "bla"

t = Time.now
task.execute
p Time.now - t
