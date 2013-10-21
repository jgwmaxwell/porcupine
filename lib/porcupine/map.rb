class Porcupine
  # In MapReduce terms, this is Input and Map together.
  class Map < Link
    # Block must accept an array of objects and emit [key, [value]] pairs
    def initialize(batch_size=1, &block)
      @batch_size = batch_size
      @map = &block
    end

    # TODO: Instance, group names
    # TODO: Failure per k1,v1?
    def call(enumerable)
      enumerable.each_slice(@batch_size).map do |objects|
        Porcupine.new do
          @map.call(objects)
        end.queue
      end.map(&:get).flatten.map do |results|
        if result.is_a?(Exception)
          getFallback(result)
        else
          result
        end
      end.compact.inject({}) do |(key, values), hash|
        hash[key] ||= []
        hash[key] += values
        hash
      end
    end

    # TODO: nil seems wrong here
    # if result is there, it's because it was the result of a map function
    # instead of the entire M/R Input function.
    def getFallback(result=nil)
      result ? result : super()
    end
  end

end