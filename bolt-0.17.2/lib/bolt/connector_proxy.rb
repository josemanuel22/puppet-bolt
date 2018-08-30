require 'socket'
require 'bolt/target'

class Connector_proxy
	def initialize(targets,options = {})
 		@targets=targets
		@proxy = Bolt::Target.new options[:proxy]
	end

	def start_connector_proxy
		@socket = UDPSocket.new
 		@socket.connect(@proxy.host, @proxy.port)
                @socket_result = UDPSocket.new
                @socket_result.bind(Socket.ip_address_list[1].ip_address, 4914)
	end

        def send_option(option)
                @socket.send option, 0, @proxy.host, @proxy.port
        end

	def send_targets
                targets_host="" 
                @targets.each do |target_host|
                  targets_host=targets_host+","+target_host.host
                  targets_host[1..-1]
                end
                targets_host = targets_host[1..-1] # We suppress the first coma
		@socket.send targets_host, 0, @proxy.host, @proxy.port
	end

	def send_command(command)
		@socket.send command, 0, @proxy.host, @proxy.port
	end

        def send_script(script)
                @socket.send script, 0, @proxy.host, @proxy.port
        end
        def rcv_result
                @socket_result.recvfrom(1000)
        end
end
