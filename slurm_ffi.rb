require 'ffi'

module GetPid
  extend FFI::Library
  ffi_lib FFI::Library::LIBC

  attach_function :getpid, [], :uint
end

module Slurm
  extend FFI::Library
  ffi_lib 'slurm'

  HIGHEST_DIMENSIONS = 5

  attach_function :slurm_api_version, [], :long

  #  For submit, allocate, and update requests 
  class JobDescriptor < FFI::Struct
    layout :account, :string,    #  charge to specified account 
      :acctg_freq, :uint16,  #  accounting polling interval (seconds) 
      :alloc_node, :string, # node making resource allocation request 
                      # NOTE: Normally set by slurm_submit* or slurm_allocate* function
      :alloc_resp_port, :uint16, #  port to send allocation confirmation to 
      :alloc_sid, :uint32, # local sid making resource allocation request NOTE: Normally set by slurm_submit* or slurm_allocate* function NOTE: Also used for update flags, see ALLOC_SID_* flags
      :argc, :uint32,    #  number of arguments to the script 
      :argv, :pointer,  #  arguments to the script 
      :begin_time, :int64,  #  delay initiation until this time 
      :ckpt_interval, :uint16, #  periodically checkpoint this job 
      :ckpt_dir, :string,   #  directory to store checkpoint images 
      :comment, :string,    #  arbitrary comment (used by Moab scheduler) 
      :contiguous, :uint16,  #  1 if job requires contiguous nodes, 0 otherwise,default=0 
      :cpu_bind, :string,   #  binding map for map/mask_cpu 
      :cpu_bind_type, :uint16, #  see cpu_bind_type_t 
      :dependency, :string, #  synchronize job execution with other jobs 
      :end_time, :int64,  #  time by which job must complete, used for job update only now, possible deadline scheduling in the future 
      :environment, :pointer, #  environment variables to set for job,  name=value pairs, one per line 
      :env_size, :uint32,  #  element count in environment 
      :exc_nodes, :string,  #  comma separated list of nodes excluded from job's allocation, default NONE 
      :features, :string,   #  comma separated list of required features, default NONE 
      :gres, :string,   #  comma separated list of required generic resources, default NONE 
      :group_id, :uint32,  #  group to assume, if run as root. 
      :immediate, :uint16, #  1 if allocate to run or fail immediately, 0 if to be queued awaiting resources 
      :job_id, :uint32,  #  job ID, default set by SLURM 
      :kill_on_node_fail, :uint16, #  1 if node failure to kill job, 0 otherwise,default=1 
      :licenses, :string,   #  licenses required by the job 
      :mail_type, :uint16, #  see MAIL_JOB_ definitions above 
      :mail_user, :string,  #  user to receive notification 
      :mem_bind, :string,   #  binding map for map/mask_cpu 
      :mem_bind_type, :uint16, #  see mem_bind_type_t 
      :name, :string,   #  name of the job, default "" 
      :network, :string,    #  network use spec 
      :nice, :uint16,    #  requested priority change, NICE_OFFSET == no change 
      :num_tasks, :uint32, #  number of tasks to be started, for batch only 
      :open_mode, :uint8,  #  out/err open mode truncate or append, see OPEN_MODE_* 
      :other_port, :uint16,  #  port to send various notification msg to 
      :overcommit, :uint8, #  over subscribe resources, for batch only 
      :partition, :string,  #  name of requested partition, default in SLURM config 
      :plane_size, :uint16,  #  plane size when task_dist = SLURM_DIST_PLANE 
      :priority, :uint32,  #  relative priority of the job, explicitly set only for user root, 0 == held (don't initiate) 
      :qos, :string,    #  Quality of Service 
      :resp_host, :string,  #  NOTE: Set by slurmctld 
      :req_nodes, :string,  #  comma separated list of required nodes default NONE 
      :requeue, :uint16, #  enable or disable job requeue option 
      :reservation, :string,  #  name of reservation to use 
      :script, :string,   #  the actual job script, default NONE 
      :shared, :uint16,  #  1 if job can share nodes with other jobs, 0 if job needs exclusive access to the node, or NO_VAL to accept the system default. SHARED_FORCE to eliminate user control. 
      :spank_job_env, :pointer, #  environment variables for job prolog/epilog scripts as set by SPANK plugins 
      :spank_job_env_size, :uint32, #  element count in spank_env 
      :task_dist, :uint16, #  see enum task_dist_state 
      :time_limit, :uint32,  #  maximum run time in minutes, default is partition limit 
      :time_min, :uint32,  #  minimum run time in minutes, default is time_limit 
      :user_id, :uint32, #  set only if different from current UID, can only be explicitly set by user root 
      :wait_all_nodes, :uint16, #  0 to start job immediately after allocation 1 to start job after all nodes booted or NO_VAL to use system default 
      :warn_signal, :uint16, #  signal to send when approaching end time 
      :warn_time, :uint16, #  time before end to send signal (seconds) 
      :work_dir, :string,   #  pathname of working directory 

      #  job constraints: 
      :cpus_per_task, :uint16, #  number of processors required for each task 
      :min_cpus, :uint32,  #  minimum number of processors required, default=0 
      :max_cpus, :uint32,  #  maximum number of processors required, default=0 
      :min_nodes, :uint32, #  minimum number of nodes required by job, default=0 
      :max_nodes, :uint32, #  maximum number of nodes usable by job, default=0 
      :sockets_per_node, :uint16, #  sockets per node required by job 
      :cores_per_socket, :uint16, #  cores per socket required by job 
      :threads_per_core, :uint16, #  threads per core required by job 
      :ntasks_per_node, :uint16, #  number of tasks to invoke on each node 
      :ntasks_per_socket, :uint16, #  number of tasks to invoke on each socket 
      :ntasks_per_core, :uint16, #  number of tasks to invoke on each core 
      :pn_min_cpus, :uint16,    #  minimum # CPUs per node, default=0 
      :pn_min_memory, :uint32, #  minimum real memory per node OR real memory per CPU | MEM_PER_CPU, default=0 (no limit) 
      :pn_min_tmp_disk, :uint32, #  minimum tmp disk per node, default=0 

      # The following parameters are only meaningful on a Blue Gene
      # system at present. Some will be of value on other system. Don't remove these
      # they are needed for LCRM and others that can't talk to the opaque data type
      # select_jobinfo.
      :geometry, [:uint16, HIGHEST_DIMENSIONS],  #  node count in various dimensions, e.g. X, Y, and Z 
      :conn_type, [:uint16, HIGHEST_DIMENSIONS], #  see enum connection_type 
      :reboot, :uint16,  #  force node reboot before startup 
      :rotate, :uint16,  #  permit geometry rotation if set 
      :blrtsimage, :string,       #  BlrtsImage for block 
      :linuximage, :string,       #  LinuxImage for block 
      :mloaderimage, :string,     #  MloaderImage for block 
      :ramdiskimage, :string,     #  RamDiskImage for block 

      # End of Blue Gene specific values */
      :req_switch, :uint32,    #  Minimum number of switches 
      :select_jobinfo, :pointer, #  opaque data type, SLURM internal use only (dynamic_plugin_data_t)
      :std_err, :string,    #  pathname of stderr 
      :std_in, :string,   #  pathname of stdin 
      :std_out, :string,    #  pathname of stdout 
      :wait4switch, :uint32,   #  Maximum time to wait for minimum switches 
      :wckey, :string            #  wckey for job 
  end

  pry

end # module Slurm

puts "got pid: #{GetPid.getpid}"
puts "slurm"
puts "api_version: #{Slurm.slurm_api_version}"

