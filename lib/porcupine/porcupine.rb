class Porcupine < com.netflix.hystrix.HystrixCommand
  java_import com.netflix.hystrix.HystrixCommand::Setter
  java_import com.netflix.hystrix.HystrixCommandKey
  java_import com.netflix.hystrix.HystrixCommandGroupKey
  java_import com.netflix.hystrix.HystrixCommandProperties

  DEFAULT_TIMEOUT = 10_000
  DEFAULT_GROUP   = "default"

  attr_reader :block

  def initialize(name_or_setter, group=DEFAULT_GROUP, timeout=DEFAULT_TIMEOUT, &block)
    @block = block

    setter = name_or_setter if name_or_setter.is_a?(com.netflix.hystrix.HystrixCommand::Setter)
    setter ||= Setter.withGroupKey(HystrixCommandGroupKey::Factory.asKey(group))
                     .andCommandKey(HystrixCommandKey::Factory.asKey(name_or_setter))
                     .andCommandPropertiesDefaults(HystrixCommandProperties::Setter().withExecutionIsolationThreadTimeoutInMilliseconds(timeout))

    super(setter)
  end

  # Execute this work immediately
  # +Blocking+, +Starts work+
  # CTC: HystrixCommand implements this already?
  def execute
    queue.get
  # Only catch Java exceptions since we already handle most exceptions in Observable#get
  rescue Java::JavaLang::Throwable => e
    raise decomposeException(e)
  end

  # Create an observer to subscribe to when work is completed.
  # +Non-blocking+, +Starts work+
  # CTC: Is this the same as HystrixCommand's "observe" that subscribes a proxy observer (ReplaySubject)?
  def observe
    Observable.new(super)
  end

  # Create an observer lazily that will kick off work when subscribed to.
  # +Non-blocking+
  def toObservable(*args)
    result = super

    # Only wrap the outer-most call; otherwise Java gets angry because the class of the
    # returned object won't match the signature when the calls recurse
    unless caller.first.match(/toObservable/) || caller.first.match(/observe/)
      result = Observable.new(result)
    end

    result
  end

  # This triggers execution in a separate thread,
  # returning a future (or "Promise").
  # Call #get on it to get on the result.
  # #get is blocking.
  # +Non-blocking+, +Starts work+
  def queue
    Future.new(super)
  end

  # Does the work, returns the result OR an exception object
  # houldn't raise since we implement #getFallback
  def run
    block.call
  end

  ##
  # If anything should go wrong with running #run above,
  # Hystrix will call this method to figure out what to do.
  #
  # === Examples
  # TODO: Below example is wrong. #get can raise
  #
  # p = Porcupine.new("watch queue", "netflix") do
  #   client = Netflix::Client.new(access_token, access_token_secret)
  #   user = client.user(user_id)
  #   user.available_disc_queue
  # end
  # future = p.queue
  # result = future.get
  # case result
  # when StandardError
  #   puts "Something went wrong! #{result.message} #{result.backtrace}"
  # when Array
  #   discs = result.discs
  #   discs.each{ ... }
  # else
  #   puts "Was expecting StandardError or Array, but got #{result.class}!"
  # end
  def getFallback
    case true
    when isFailedExecution
      # This is the error that your block emitted
      getFailedExecutionException.getException
    when isResponseRejected
      RejectedError.new
    when isResponseShortCircuited
      ShortCircuitError.new
    when isResponseTimedOut
      TimeoutError.new
    else
      RuntimeError.new
    end
  end
end
