#!/usr/bin/env ruby
require 'pry'
require './cloister.rb'

x = 2
y = 5

# puts "# Local:"
# l = Cloister::Local.new
# l.run {
#   puts "Hello world, x+y=#{x+y}."
#   puts `hostname`
# }

# $slurm = Cloister::Slurm.new

# (1..10).each do |i|
#   $slurm.run {
#     puts "Hello from iteration #{i} on #{`hostname`}:"
#     puts "x+y = #{x+y}"
#   }
# end

# $slurm.sync
# puts $slurm.jobs

$batch = Cloister::Batch.new
(1..10).each do |i|
  $batch.run {
    puts "Hello from iteration #{i} on #{`hostname`}:"
    puts "x+y = #{x+y}"
  }
end

$batch.run {
  @@_not_isolated_vars = :global
	puts "Running long job..."
  (0..30).each {|i|
    sleep(4)
    puts(%Q[done with iteration #{i}\n])
  }
}

$batch.pry
