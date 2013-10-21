class Porcupine
  class Link < Porcupine
    def initialize(next_link, &block)
      @next_link = next_link
      @block = block
      @args = []
      @yielded = false
      @result = nil
    end

    def bind(*args)
      @args = args
      self
    end

    def run
      value = @block ? @block.call(*@args) : self.call(*@args)
      self.yield(*value)
    end

    def yield(*value)
      return value unless @next_link
      return @result if @yielded
      raise "No next link!" unless @next_link

      @yielded = true

      @result = @next_link.bind(*value).execute
    end
  end
end