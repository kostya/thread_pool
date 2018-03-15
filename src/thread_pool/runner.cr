class Thread
  def self.remove_thread(th)
    @@threads.delete(th)
  end
end

class ThreadPool
  class Runner
    getter threads

    class ThreadInfo
      getter thread, id, r1, r2, w1, w2

      def initialize(@thread : Thread, @id : Int32, @r1 : IO::FileDescriptor, @r2 : IO::FileDescriptor, @w1 : IO::FileDescriptor, @w2 : IO::FileDescriptor)
      end
    end

    def initialize(@size : Int32, @debug = false)
      @tasks_channel = Channel(UInt64).new

      @mutex_requests = Thread::Mutex.new
      @mutex_results = Thread::Mutex.new

      @requests = {} of UInt64 => Task
      @results = {} of UInt64 => Task
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
      @tasks_channel.close
    end

    def push_task(task : Task)
      id = task.thread_pool_id

      @mutex_requests.synchronize do
        @requests[id] = task
      end

      @tasks_channel.send(task.thread_pool_id)

      true
    end

    def result_by_id(task_id)
      @mutex_results.synchronize do
        @results.delete(task_id)
      end
    end

    def stats
      {
        requests_size: @requests.size,
        results_size:  @results.size,
        threads:       @threads.size,
      }
    end

    private def request_by_id(task_id)
      @mutex_requests.synchronize do
        @requests.delete(task_id)
      end
    end

    private def push_result(task_id, task)
      @mutex_results.synchronize do
        @results[task_id] = task
      end
    end

    private def _run
      spawn do
        loop do
          id = @tasks_channel.receive
          @threads.each do |ti|
            ti.w1.write_bytes(id, IO::ByteFormat::LittleEndian)
          end
          break if @stopped
        end
      end

      @size.times do |i|
        ti = add_thread(i)
        @threads << ti
        sleep 0.01 # this is quite needed, dont know why, but else it crashed
      end
    end

    private def add_thread(id)
      # send flag to thread about new task
      r1, w1 = IO.pipe(read_blocking: true, write_blocking: false)

      # send flag from thread about result ready
      r2, w2 = IO.pipe(read_blocking: false, write_blocking: true)

      th = Thread.new { thread_main(id, r1, w2) }
      ThreadInfo.new(thread: th, id: id, r1: r1, r2: r2, w1: w1, w2: w2)
    end

    private def thread_main(thread_id, r1, w2)
      loop do
        begin
          task_id = r1.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
        rescue Errno
        end
        break if @stopped
        thread_execute_task(thread_id, task_id, w2) if task_id
        break if @stopped
      end
    end

    private def thread_execute_task(thread_id, task_id, w2)
      if req = request_by_id(task_id)
        debug_msg { "thread<#{thread_id}> get task #{req.inspect}" }
        req.execute
        push_result(task_id, req)
        w2.write_bytes(task_id, IO::ByteFormat::LittleEndian)
      end
    end

    private def debug_msg
      {% unless flag?(:release) %}
      puts yield if @debug
      {% end %}
    end
  end
end
