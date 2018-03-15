class ThreadPool
  class Runner
    getter threads

    record ThreadInfo, thread : Thread, read_results : IO::FileDescriptor, write_flag : IO::FileDescriptor

    def initialize(@size : Int32)
      @mutex_requests = Thread::Mutex.new
      @mutex_results = Thread::Mutex.new

      @requests = Deque(Task).new
      @results = Deque(Task).new
      @threads = Array(ThreadInfo).new
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
      # set notifications for threads to wake up
      @threads.each { |th| th.write_flag.write_byte(1_u8) }

      # add task
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
      # send flag to thread about new task
      r1, w1 = IO.pipe(read_blocking: true, write_blocking: false)

      # send flag from thread about result ready
      r2, w2 = IO.pipe(write_blocking: false)

      th = Thread.new { thread_main(r1, w2) }
      ThreadInfo.new(th, r2, w1)
    end

    private def thread_main(r1, w2)
      loop do
        r1.read_byte
        break if @stopped
        thread_execute_task(w2)
        break if @stopped
      end
    end

    private def thread_execute_task(w2)
      if req = receive_request
        req.execute
        push_results(req)
        w2.write_byte(1_u8)
      end
    end
  end
end
