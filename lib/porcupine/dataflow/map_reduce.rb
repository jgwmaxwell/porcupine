class Porcupine
  # In MapReduce terms, this is Input/Map together.
  # Map and Reduce, at least in framework code, are the same.
  class MapFunction < Porcupine
    def getFallback
      []
    end
  end

  # TODO: This doesn't take into account other threads working currently,
  # we need some thread sharing instead of thread shedding.
  THREADS = 10
  class MapReduce < Link
    # Block must accept an array of objects and emit [key, [value]] pairs
    def initialize(instance_name, group_name, map_function_class=MapFunction, threads=THREADS, &block)
      super(instance_name, group_name, &nil)
      @threads = threads || THREADS
      @map_function_class = map_function_class || MapFunction
      @map = block
    end

    # TODO: Instance, group names
    def call(enumerable)
      enumerable.each_slice(slice_size(enumerable)).map.with_index do |objects, index|
        @map_function_class.new(instance_name + "::index:#{index}", group_name) do
          @map.call(objects)
        end.queue
      end.map(&:get).inject({}) do |hash, pairs|
        pairs.each do |key, value|
          hash[key] ||= []
          hash[key] << value
        end
        hash
      end
    end

    private

    def slice_size(enumerable)
      [enumerable.size/@threads, 1].max
    end
  end

end