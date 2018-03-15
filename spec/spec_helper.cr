require "spec"
require "../src/thread_pool"
require "digest/md5"

class SpecTask
  include ThreadPool::Task

  getter result : String?

  def initialize(@str : String)
  end

  def execute
    @result = Digest::MD5.hexdigest(@str)
  end
end

# def with_thread_pool(size)
#   pool = ThreadPool.new(size: size)
#   pool.run
#   sleep 0.1

#   yield pool
# ensure
#   pool.try &.stop
#   sleep 0.1
# end

def should_spend(timeout, delta = timeout / 5.0)
  t = Time.now
  res = yield
  delta = 0.02 if delta < 0.02
  (Time.now - t).to_f.should be_close(timeout, delta)
  res
end

POOLS = {} of Int32 => ThreadPool

(1..10).each do |cnt|
  pool = ThreadPool.new(size: cnt, debug: true)
  pool.run
  POOLS[cnt] = pool
end

sleep 1.0

class CalculateMD5
  @finished_at : Time?

  def initialize(@tasks_count : Int32, @threads_count : Int32)
    @tasks = [] of SpecTask
    @tasks_count.times do |i|
      task = SpecTask.new(i.to_s)
      @tasks << task
    end
    @created_at = Time.now
    @results = {} of Int32 => String
  end

  def calc_single
    @tasks.each { |task| task.execute }
    self
  end

  def calc_in_threads
    @tasks.each { |task| POOLS[@threads_count].push(task) }
    @tasks.each { |task| task.wait }

    self
  end

  def result
    res = ""
    @tasks.each do |task|
      res = Digest::MD5.hexdigest("#{res} - #{task.result.not_nil!}")
    end
    @finished_at = Time.now
    res
  end

  def duration
    if f = @finished_at
      f - @started_at
    end
  end
end
