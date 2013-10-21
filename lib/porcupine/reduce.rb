class Porcupine
  class Reduce < Link
    def initialize(&block)
      @reduce = &block
    end

    # TODO: Instance, group names
    # TODO: Failure per k1,v1?
    # TODO: batching per porcupine
    def call(enumerable)
      enumerable.map do |key, values|
        Porcupine.new do
          @reduce.call(key, values)
        end.queue
      end.map(&:get).map do |result|
        if result.is_a?(Exception)
          getFallback(result)
        else
          result
        end
      end.compact.inject({}) do |(key, value), hash|
        hash[key] ||= []
        hash[key] = value
        hash
      end
    end

    def getFallback(result)
      result ? result : super()
    end
  end

end