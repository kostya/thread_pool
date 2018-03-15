require "../src/thread_pool"

class Task
  include ThreadPool::Task

  getter result : Int32?

  def initialize(@i1 : Int32, @i2 : Int32)
  end

  def execute
    @result = @i1 + @i2
  end
end

# run 4 background threads
pool = ThreadPool.new(size: 4).run

tasks = Array.new(10000) { |i| Task.new(i, i + 1) }

t = Time.now
s = 0_u64

tasks.each { |t| pool << t }
tasks.each { |t| t.wait }
tasks.each { |t| s += t.result.not_nil! }

p s
p Time.now - t
