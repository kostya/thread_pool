require "./thread_pool/*"

class ThreadPool
  VERSION = "0.3"

  def initialize(size : Int32, wait_task_mks = 10000, @receive_task_mks = 50000)
    @runner = Runner.new(size, wait_task_mks)
    @stopped = false
  end

  def push(task : Task)
    task.result_channel # just instantinate it
    @runner.push_task(task)
    task
  end

  def execute(task : Task)
    push(task).wait
  end

  def run
    @stopped = false
    @runner.run
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
    spawn do
      loop do
        interval = @receive_task_mks / 1_000_000.0
        loop do
          res = @runner.receive_task
          if res
            begin
              res.result_channel.send(nil)
            rescue Channel::ClosedError
            end
          else
            sleep(interval)
          end
          break if @stopped
        end
      end
    end
  end
end
