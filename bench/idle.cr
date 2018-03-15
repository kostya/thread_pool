require "../src/thread_pool"

pool = ThreadPool.new(size: 100).run
p :started
sleep
