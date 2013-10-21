require "delegate"

class Porcupine
  class Observable < SimpleDelegator
    ##
    # Subscribe a block (or a few) to be called when this work is completed.
    # This follows RxJava's [Observable API](http://netflix.github.io/RxJava/javadoc/rx/Observable.html)
    #
    # === Parameters
    #
    # There are three kinds of blocks that may be executed depending on what happens
    # when your Porcupine work is completed or fails:
    #
    # [callback]  "onNext" is evaluated when there are no errors. (REQUIRED)
    # [errback]   "onError" is evaluated upon an error.
    # [completed] "onCompleted" is evaluated after all onNext callbacks
    #             have completed and no errors were thrown.
    #             Currently onNext will only fire once.
    #
    # And an optional parameter to control thread scheduling:
    # 
    # [scheduler] "scheduler" is an [RxJava](http://netflix.github.io/RxJava/javadoc/rx/Scheduler.html)
    #
    # === Examples
    #
    # # With one callback
    # p = Porcupine.new("hard_work", "bbbig_data") { sleep(1000); "tiny data" }
    # callback = lambda {|response| puts response }
    # observer = p.observe
    # observer.subscribe(callback)
    # observer.toBlockingObservable.last # Block and force computation
    # (On success) => "tiny data"
    # (On error) => <SWALLOWED, nothing happens>
    #
    # # Or like this:
    # p = Porcupine.new("hard_work", "bbbig_data") { sleep(1000); "tiny data" }
    # observer = p.observe
    # observer.subscribe{|response| puts response }
    # observer.toBlockingObservable.last # Block and force computation
    # (On success) => "tiny data"
    # (On error) => <SWALLOWED, nothing happens>
    #
    # # With errback
    # p = Porcupine.new("hard_work", "bbbig_data") { sleep(1000); "tiny data" }
    # callback = lambda {|response| puts response }
    # errback = lambda do |exception| 
    #   puts exception.class
    # end
    # observer = p.observe
    # observer.subscribe(callback, errback)
    # observer.toBlockingObservable.last # Block and force computation
    # (On success) => "tiny data"
    # (On timeout error) => "Porcupine::Failure::TimeoutError"
    def subscribe(*args, &block)
      raise ArgumentError unless block_given? || args.first

      on_next = if block_given?
                  block
                else
                  args.shift
                end

      on_error = !block_given? && args.shift

      wrapped = lambda do |value_or_exception|
        if value_or_exception.is_a?(Exception)
          on_error && on_error.call(value_or_exception)
        else
          on_next.call(value_or_exception)
        end
      end

      if on_error
        __getobj__.subscribe(wrapped, on_error, *args)
      else
        __getobj__.subscribe(wrapped)
      end
    end
  end
end
