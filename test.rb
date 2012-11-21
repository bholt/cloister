#!/usr/bin/env ruby
require 'pry'
require './cloister.rb'

x = 2
y = 5

# puts "# Local:"
# l = Cloister::LocalExecutor.new
# l.run {
#   puts "Hello world, x+y=#{x+y}."
#   puts `hostname`
# }

# $slurm = Cloister::SlurmExecutor.new

# (1..10).each do |i|
#   $slurm.run {
#     puts "Hello from iteration #{i} on #{`hostname`}:"
#     puts "x+y = #{x+y}"
#   }
# end

# $slurm.sync
# puts $slurm.jobs

$batch = Cloister::BatchExecutor.new
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
    puts "done with iteration #{i}"
    $stdout.flush
  }
}

$batch.pry
$batch.status
