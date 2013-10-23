require 'pp'
require 'porcupine'

# class TestText < Porcupine::Link
#   def initialize
#     super("Gutenburg File #{Time.now.to_f}", "MapReduce")
#     @file = File.expand_path('comedy_of_masks.txt', File.dirname(__FILE__))
#   end
  
#   def call
#     File.read(@file)
#   end
# end

class TestText < Porcupine::Link
  require "net/http"
  require "uri"
  def initialize
    super("Gutenburg Http #{Time.now.to_f}", "MapReduce")
    @url = "http://www.gutenberg.org/files/16703/16703.txt"
  end

  def call
    Net::HTTP.get_response(URI.parse(@url)).body
  end
end

class Array
  def sum
    inject(0){|e, s| e+s}
  end
end



chain = Porcupine::Chain.new('chain' + Time.now.to_f.to_s, 'MapReduce')

# Read in the file
chain << TestText.new

# Split by whitespace
chain << ->(text){ text.split(/\s+/) }

# Map each word to a value of 1
chain << Porcupine::MapReduce.new('Map' + Time.now.to_f.to_s, 'MapReduce') do |xs|
  xs.map{|x| [x, 1]}
end

# Reduce by summing
chain << Porcupine::MapReduce.new('Reduce' + Time.now.to_f.to_s, 'MapReduce') do |xs|
  xs.map do |key, values|
    [key, values.sum]
  end
end

# Sort by sum
chain << ->(hash){ hash.invert.sort_by{|k, v| k}.reverse }

start = Time.now
require 'pp'
pp chain.get
puts stop = Time.now-start

# => 4.049