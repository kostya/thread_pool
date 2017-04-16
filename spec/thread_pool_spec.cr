require "./spec_helper"

describe ThreadPool do
  it "single" do
    c = CalculateMD5.new(1000, 0)
    c.calc_single
    c.result.should eq "389bd6fe043b183b22438d4ff64e3230"
  end

  (1..10).each do |i|
    it "threaded #{i}" do
      c = CalculateMD5.new(1000, i)
      c.calc_in_threads
      c.result.should eq "389bd6fe043b183b22438d4ff64e3230"
    end
  end
end
