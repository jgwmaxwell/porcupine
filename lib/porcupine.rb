require "jbundler"

require "porcupine/porcupine"
require "porcupine/exceptions"
require "porcupine/future"
require "porcupine/observable"
require "porcupine/dataflow/chain"
require "porcupine/dataflow/link"
require "porcupine/dataflow/map_reduce"

# https://github.com/Netflix/Hystrix/issues/102
# Prevents hanging on exit by issuing shutdown
at_exit do
  com.netflix.hystrix.Hystrix.reset
end