class Thread
  def self.remove_thread(th)
    @@threads.delete(th)
  end
end

class ThreadPool
  class Runner
    getter threads

    record ThreadInfo, thread : Thread, id : Int32, r1 : IO::FileDescriptor, r2 : IO::FileDescriptor, w1 : IO::FileDescriptor, w2 : IO::FileDescriptor

    def initialize(@size : Int32, @debug = false)
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
      @threads.each do |ti|
        Thread.remove_thread(ti.thread)
        ti.r2.close
        ti.w1.close
      end
      @threads.clear
    end

    def push_task(task : Task)
      # set notifications for threads to wake up
      @threads.each { |th| th.w1.write_byte(1_u8) }

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
      @size.times do |i|
        @threads << add_thread(i)
        sleep 0.01 # this is quite needed, dont know why, but else it crashed
      end
    end

    private def add_thread(id)
      # send flag to thread about new task
      r1, w1 = IO.pipe(read_blocking: true, write_blocking: false)

      # send flag from thread about result ready
      r2, w2 = IO.pipe(write_blocking: false)

      th = Thread.new { thread_main(id, r1, w2) }
      ThreadInfo.new(thread: th, id: id, r1: r1, r2: r2, w1: w1, w2: w2)
    end

    private def thread_main(id, r1, w2)
      loop do
        begin
          r1.read_byte
        rescue Errno
        end
        break if @stopped
        thread_execute_task(id, w2)
        break if @stopped
      end
    end

    private def thread_execute_task(id, w2)
      if req = receive_request
        debug_msg { "thread<#{id}> get task #{req.inspect}" }
        req.execute
        push_results(req)
        w2.write_byte(1_u8)
      end
    end

    private def debug_msg
      {% unless flag?(:release) %}
      puts yield if @debug
      {% end %}
    end
  end
end
