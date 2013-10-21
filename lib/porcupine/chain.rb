class Porcupine
  class Chain
    def initialize(instance_name, group_name)
      @instance_name, @group_name = instance_name, group_name
      @links = []
      @futures = {}
    end

    def add(link)
      # Allows adding ad-hoc procs/lambdas like
      # chain << ->(tweets){ puts tweets.inspect }
      if link.is_a?(Proc)
        link = Link.new(&link)
      end

      last_link = @links.last

      @links << link
      
      if last_link
        last_link.next_link = link
      end

      link
    end
    alias_method :add, :<<

    def queue(*args)
      @futures[args] ||= @links.first.bind(*args).queue
    end

    def get(*args)
      queue(*args).get
    end
  end
end