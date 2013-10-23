class Porcupine
  # Override #call or specify a block to call with values.
  attr_accessor :next_link
  attr_reader :instance_name, :group_name

  class Link < Porcupine
    def initialize(instance_name, group_name, &block)
      super(instance_name, group_name)
      @instance_name = instance_name
      @group_name = group_name
      @next_link = nil
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
      # End the chain, start unwinding
      return value unless @next_link
      self.yield(value)
    # rescue => e
    #   e.message << " in Link #{instance_name}/#{group_name}"
    #   raise e
    end

    def yield(value)
      return @result if @yielded
      # Basically, you can't have around filters as the last link of a chain
      # (there's nothing to wrap around)
      raise "No next link!" unless @next_link

      @yielded = true

      @result = @next_link.bind(value).execute
    end
  end
end