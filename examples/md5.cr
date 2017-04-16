require "../src/thread_pool"
require "digest/md5"

# Calculate CPU heavy task

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

start_at = Time.now
tasks_count = (ARGV[1]? || 10).to_i
tasks = [] of Task
tasks_count.times do |i|
  task = Task.new(i.to_s)
  tasks << task
end

results = {} of Int32 => String

threads_count = (ARGV[0]? || 10).to_i
puts "start with #{threads_count} threads, tasks #{tasks_count}"
pool = ThreadPool.new(size: threads_count)
pool.run

if threads_count == 0
  tasks.each_with_index { |task, i| results[i] = task.execute }
else
  tasks.each { |task| pool.push(task) }
  tasks.each { |task| task.wait }
  tasks.each_with_index { |task, i| results[i] = task.result.not_nil! }
end

res = ""
tasks_count.times do |i|
  res = Digest::MD5.hexdigest("#{res} - #{results[i]}")
end

puts res
puts Time.now - start_at
