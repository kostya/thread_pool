require "./thread_pool/*"

class ThreadPool
  VERSION = "0.3"

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
            ti.r2.read_byte
          rescue Errno
          end
          break if @stopped
          res = @runner.receive_task
          if res
            begin
              res.result_channel.send(nil)
            rescue Channel::ClosedError
            end
          end
          break if @stopped
        end
      end
    end
  end
end
