class Connector_proxy
	def initialize(target)
 		@target=target
		@proxy=Target.new options[':proxy']
	end

	def start_connector_proxy
		@socket = UDPSocket.new
 		@socket.connect(@proxy.host, @proxy.port)	
	end

	def send_target
		@socket.send @target.host, 0, @proxy.host, @proxy.port
	end

	def send_command(command)
		@socket.send command, 0, @proxy.host, @proxy.port
	end
        
        def rcv_result
                @socket.recvfrom(100)
        end
end
