require "./thread_pool/*"

class ThreadPool
  VERSION = "0.3"

  @@original_id : UInt64 = 0_u64

  def self.next_id
    @@original_id += 1
    @@original_id = 0_u64 if @@original_id == UInt64::MAX
    @@original_id
  end

  def initialize(@size : Int32, @debug = false)
    @runner = Runner.new(@size, @debug)
    @stopped = false
  end

  def push(task : Task)
    task.result_channel # just instantinate it
    @runner.push_task(task)
    task
  end

  def <<(task : Task)
    push(task)
  end

  def execute(task : Task)
    push(task).wait
  end

  def run
    @stopped = false
    @runner.run
    loop do
      sleep 0.1
      break if @runner.threads.size == @size
    end
    run_mapper
    self
  end

  def stop
    @stopped = true
    @runner.try &.stop
  end

  def stats
    @runner.stats
  end

  private def run_mapper
    @runner.threads.each do |ti|
      spawn do
        loop do
          begin
            task_id = ti.r2.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
          rescue Errno
          end
          break if @stopped
          if task_id
            res = @runner.result_by_id(task_id)
            if res
              begin
                res.result_channel.send(nil)
              rescue Channel::ClosedError
              end
            end
          end
          break if @stopped
        end
      end
    end
  end
end
