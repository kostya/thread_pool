class ThreadPool
  class Runner
    def initialize(@size : Int32, @wait_task_mks = 10000)
      @mutex_requests = Thread::Mutex.new
      @mutex_results = Thread::Mutex.new

      @requests = Deque(Task).new
      @results = Deque(Task).new
      @threads = [] of Thread
      @stopped = false
    end

    def run
      @stopped = false
      spawn { _run }
    end

    def stop
      @stopped = true
      @threads.clear
    end

    def push_task(task : Task)
      @mutex_requests.synchronize do
        @requests << task
        true
      end
    end

    def receive_task
      @mutex_results.synchronize do
        @results.shift?
      end
    end

    def stats
      {
        requests_size: @requests.size,
        results_size:  @results.size,
        threads:       @threads.size,
      }
    end

    private def receive_request
      @mutex_requests.synchronize do
        @requests.shift?
      end
    end

    private def push_results(res)
      @mutex_results.synchronize do
        @results << res
      end
    end

    private def _run
      @size.times do
        @threads << add_thread
        sleep 0.01 # this is quite needed, dont know why, but else it crashed
      end
    end

    private def add_thread
      Thread.new do
        loop do
          if req = receive_request
            req.execute
            push_results(req)
          else
            LibC.usleep(@wait_task_mks)
          end
          break if @stopped
        end
      end
    end
  end
end
