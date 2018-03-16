require "../src/thread_pool"

pool = ThreadPool.new(size: 200).run
p :started
sleep
