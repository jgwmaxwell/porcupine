# A PRICKLE OF PORCUPINES TO DO YOUR WORK IN PARALLEL
# Another way to acomplish this is with futures/promises. TODO: Write docs on that.
# This is mostly to move from Typheous/Hydra.
#
# === Example
#
# p = Porcupine.new("user_timeline", "Twitter") do
#   Twitter.user_timeline(213747670)
# end
# 
# callback = lambda do |tweets|
#   tweets.each{|tweet| puts "#{tweet.from_user_name}: #{tweet.text}"}
# end
#
# errback = lambda do |exception|
#   puts "ARGH TWITTER OR SOMETHING BAD"
# end
#
# complete = lambda do
#   puts "Timeline requested successfully."
# end
#
# o = p.observer(callback, errback, complete)
# prickle = Porcupine::Prickle.singleton
# prickle << o
# # ... Do some other things, adding to the prickle
# # Block until all observers have run
# prickle.run
class Porcupine
  class Prickle
    class << self
      def singleton
        Thread.current[:porcupine_prickle] = new
      end
    end

    def initialize
      @queue = []
    end

    def <<(observer)
      @queue << observer
    end
    alias_method :<<, :add

    def run
      @queue.each{|o| o.toBlockingObservable.last}
    end
  end
end