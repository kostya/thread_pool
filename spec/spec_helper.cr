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
    pool = ThreadPool.new(size: @threads_count)
    pool.run
    sleep 0.1

    @tasks.each { |task| pool.push(task) }
    @tasks.each { |task| task.wait }

    self
  ensure
    pool.try &.stop
    sleep 0.1
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
