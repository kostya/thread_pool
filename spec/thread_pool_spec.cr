require "./spec_helper"

describe ThreadPool do
  it "single" do
    c = CalculateMD5.new(1000, 0)
    c.calc_single
    c.result.should eq "389bd6fe043b183b22438d4ff64e3230"
  end

  it "single execute" do
    task = SpecTask.new("bla")
    POOLS[1].execute(task)
    task.result.should eq "128ecf542a35ac5270a87dc740918404"
  end

  (1..10).each do |i|
    it "threaded #{i}" do
      c = CalculateMD5.new(1000, i)
      c.calc_in_threads
      c.result.should eq "389bd6fe043b183b22438d4ff64e3230"
    end
  end

  it "stats" do
    pool = ThreadPool.new(1)
    pool.run
    sleep 0.2
    pool.stats.should eq({requests_size: 0, results_size: 0, threads: 1})
    pool.stop
  end
end
