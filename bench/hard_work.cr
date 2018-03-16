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

size = (ARGV[0]? || 4).to_i

p "started with #{size} threads"

# run 4 background threads
pool = ThreadPool.new(size: size).run

def cycle(pool)
  t = Time.now
  s = 0_u64

  tasks = Array.new(100000) { |i| Task.new(i, i + 1) }
  tasks.each { |t| pool.push t }
  tasks.each { |t| t.wait }
  tasks.each { |t| s += t.result.not_nil! }

  p s
  p Time.now - t
end

loop do
  cycle(pool)
  sleep 0.5
end
