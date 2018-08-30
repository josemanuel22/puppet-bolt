require 'daemons'
require 'bolt/proxy/proxy'
 
task1 = Daemons.call(:multiple => true) do
  # first server task
  loop do
    proxy = Proxy.new
    proxy.start
    while true do
      option = proxy.rcv_option
      case option
      when "command"
        proxy.process_command
      when "script"
        proxy.process_script #TODO REWRITTE CODE
      when "task"
        #TODO
      when "plan"
        #TODO 
      end
    end
  end
end


