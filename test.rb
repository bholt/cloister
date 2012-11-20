#!/usr/bin/env ruby
require 'securerandom'
require 'pry'
require './cloister.rb'


x = 2
y = 5
# run_from_script { puts "Hello world." }
# puts "# Local:"

# l = RbCluster::LocalExecutor.new
# l.run {
#   puts "Hello world, x+y=#{x+y}."
#   puts `hostname`
# }

slurm = Cloister::SlurmExecutor.new

# puts "# Slurm:"
# slurm.run_sync {
#   puts "Hello world, x+y=#{x+y}."
#   puts `hostname`
# }

def say_hello
  slurm.run {
    puts "Hello from iteration #{i} on #{`hostname`}:"
    puts "#{x} + #{y} = #{x+y}"
  }
end

(1..10).each do |i|
  say_hello
end
# joiner = Thread.new { slurm.sync_all }

$ui = Thread.new { binding.pry; slurm.stay_alive = false }

slurm.sync(true)
$ui.join

# puts slurm.jobs

# sproc = SerializableProc.new do
#   @@_not_isolated_vars = :global # globals won't be isolated
#   puts "WakeUp!"         # $stdout is the $stdout in the execution context
# end
# Marshal.load(Marshal.dump(sproc)).call
