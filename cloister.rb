# define 'supress_warnings' (could be in generic helper lib if we had one)
module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

# suppressing warnings because we're using a non-standard version of 'sourcify' which causes conflicts with the dependences of 'serializable_proc' (but it works anyway)
suppress_warnings { require 'serializable_proc' }
require 'set'
require 'fiber'
require 'securerandom'
require 'colored'

require 'file-tail'
class File
  include File::Tail
end

module Cloister
  def self.make_script(path=Dir.tmpdir, &blk)
    sproc = SerializableProc.new(&blk)
    f = "#{path}/cloister.#{Process.pid}.#{SecureRandom.hex(2)}.rb"
    File.open(f, 'w') {|o| o.write(
      %Q[#!/usr/bin/env ruby\n#encoding: ascii-8bit
        require './cloister.rb'
        s = '#{Marshal.dump(sproc)}'
        Marshal.load(s).call(binding)
    ])}
    return f
  end

  class Executor
    attr_reader :jobs
    attr_accessor :stay_alive

    def initialize
      @jobs = {}
      @running = Set.new
      @stay_alive = false
    end

    def sync(stay_alive = false)
      @stay_alive = stay_alive

      while @running.size > 0 || @stay_alive
        @running.each { |t|
          if t.alive?
            t.resume
          else
            @running.delete t
          end
        }
      end
    end
  end

  class BatchJob
    attr_reader :jobid, :state, :nodes, :out_file
    def initialize(out_file)
      @out_file = out_file
    end

    def update(sinfo) # Slurm::JobInfo
      @jobid = sinfo[:job_id]
      @state = sinfo[:job_state]
      @nodes = sinfo[:nodes]
      @start_time = sinfo[:start_time]
      @end_time = sinfo[:end_time]
    end

    def to_s()
      time = @state == :JOB_COMPLETE ? total_time : elapsed_time
      "#{@jobid}: #{@state} on #{@nodes}, time: #{time}"
    end

    def elapsed_time() Time.at(Time.now.tv_sec - @start_time).gmtime.strftime('%R:%S') end
    def total_time()   Time.at(@end_time - @start_time).gmtime.strftime('%R:%S') end
    def out()          @out ||= File.open(@out_file, 'r') end
    def tail
      stop_tailing = false
      out.backward(10).tail {|l|
        puts l
        break if stop_tailing
      }
    end
  end

  class Local < Executor
    def run(&blk)
      puts `ruby #{Cloister.make_script(&blk)}`
    end
  end

  class Batch < Executor
    def initialize()
      super()
      @default_flags = {nnode:4, ppn:2, partition:'grappa'}
    end

    def run(flags = {}, &blk)
      flags = @default_flags.merge(flags)
      d = "#{Dir.pwd}/.cloister"
      begin Dir.mkdir(d) rescue Errno::EEXIST end

      f = Cloister.make_script(d, &blk)
      fout = "#{d}/cloister.%j.out"
      cmd = "#{File.dirname(__FILE__)}/cloister_sbatch.sh '#{File.dirname f}' '#{File.basename f}' #{`hostname`.strip}"
      s = `sbatch --nodes=#{flags[:nnode]} --ntasks-per-node=#{flags[:ppn]} --partition=#{flags[:partition]} --output=#{fout} --error=#{fout} #{cmd}`
      jobid = s[/Submitted batch job (\d+)/,1].to_i
      @jobs[jobid] = BatchJob.new(fout.gsub(/%j/,jobid.to_s))
      @running << jobid
      return jobid
    end

    def update
      require './slurm_ffi.rb'
      @running.each do |jobid|
        jptr = FFI::MemoryPointer.new :pointer
        Slurm.slurm_load_job(jptr, jobid, 0)
        jmsg = Slurm::JobInfoMsg.new(jptr.get_pointer(0))
        raise "assertion failure" unless jmsg[:record_count] == 1
        info = Slurm::JobInfo.new(jmsg[:job_array])

        @jobs[jobid].update(info)

        Slurm.slurm_free_job_info_msg(jmsg)
      end
    end

    def jobs
      update
      return @jobs
    end

    def status
      update
      @index = []
      @jobs.each {|k,v|
        puts "[#{"%2d" % @index.size}] ".blue + v.to_s
        @index << k
      }
      return
    end
    def job(n) @jobs[@index[n]] end
  end

  class Slurm < Executor
    def initialize()
      super()
      @default_flags = {nnode:4, ppn:2, partition:'grappa'}
    end

    def run(flags = {}, &blk)
      flags = @default_flags.merge(flags)
      f = Cloister.make_script(&blk)

      cmd = "#{File.dirname(__FILE__)}/cloister_sbatch.sh '#{File.dirname f}' '#{File.basename f}' #{`hostname`.strip}"

      t = Fiber.new do
        pout = IO.popen(["salloc","--nodes=#{flags[:nnode]}","--ntasks-per-node=#{flags[:ppn]}","--partition=#{flags[:partition]}","sh",*cmd.split(" "), :err=>[:child,:out]])
        @jobs[pout.pid] = {running:true}
        output = ""
        Fiber.yield # yield now that job has been submitted

        while true do
          r = IO.select([pout], nil, nil, 0.01)
          if r
            begin
              tmp = pout.readpartial(1024)
              # puts tmp.strip
              output += tmp
            rescue
              break
            end
          end
          Fiber.yield
        end
        @jobs[pout.pid] = {output:output}
      end
      @running << t
      t.resume # returns after submitting job
      return t
    end

    def run_sync(flags={}, &blk)
      flags = @default_flags.merge(flags)

      t = run(flags, &blk)
      while t.alive? do t.resume end
      puts "back in main, fiber alive? #{t.alive?}"
      puts @jobs
    end

  end # SlurmExecutor

end # module Cloister
