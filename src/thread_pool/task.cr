class ThreadPool
  module Task
    abstract def execute

    @result_channel : Channel::Buffered(Nil)?

    def result_channel
      @result_channel ||= Channel::Buffered(Nil).new(1)
    end

    def wait
      raise "no result_channel" unless @result_channel
      result_channel.receive
    end
  end
end
