class Porcupine
  class Failure < RuntimeError
    class RejectedError < Failure; end
    class ShortCircuitError < Failure; end
    class TimeoutError < Failure; end
  end
end
