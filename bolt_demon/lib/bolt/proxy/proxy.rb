require 'socket'
require 'bolt/proxy/connections'
require 'bolt/proxy/connection'
require 'bolt/transport/ssh/connection'
require 'bolt/connections_pool/connections_pool'
require 'bolt/target'

require 'net/ssh/config'
require 'net/ssh/errors'
require 'net/ssh/loggable'
require 'net/ssh/transport/session'
require 'net/ssh/authentication/session'
require 'net/ssh/connection/session'
require 'net/ssh/prompt'

$MAXLEN=2018

class Proxy
  def initialize
    @port=4913
    @connections = Connections.new(Connections_pool.new)
  end 

  def start
    @socket = UDPSocket.new
    @socket.bind(Socket.ip_address_list[1].ip_address, @port)
  end

  def rcv_option
    @socket.recvfrom($MAXLEN)[0]
  end

  def rcv_target
    @socket.recvfrom($MAXLEN)
  end

  def rcv_command
    @socket.recvfrom($MAXLEN)
  end

  def rcv_script
    @socket.recvfrom($MAXLEN)
  end

  def send_result(results, dest_ip)
    socket_result = UDPSocket.new
    socket_result.connect(dest_ip, 4914)
    results_json= Hash.new
    results.each do |host_result|
      host_result.each do |host, result|
        result_json = {
          "stdout" => result.stdout.string.to_s,
          "stderr" => result.stderr.string.to_s,
          "exit_code" => result.exit_code.to_s
        }
        results_json.merge!({"#{host}" => result_json})
      end
    end
    puts results_json.to_json.to_s
    socket_result.send results_json.to_json.to_s, 0, dest_ip, 4914
  end

  def process_command
    targets_ip, sender_addrinfo = rcv_target
    command,_ = rcv_command
    results = Array.new
    targets_ip.split(",").each do |target_ip|
      target = Bolt::Target.new target_ip
      if @connections.is_there_connection?(target.host)
        c = @connections.get_connection(target.host)
        result = c.execute(command)
      else
        connection = Bolt::Transport::SSH::Connection.new target
        connection.connect
        @connections.add_connection(connection)
        result = connection.execute(command)
      end
      results << {"#{target.host}"=> result}
    end
    send_result(results,sender_addrinfo[2])
  end

  def process_script
    #TODO REWRITTE
    target_ip, sender_addrinfo = rcv_target
    script,_ = rcv_script
    target = Bolt::Target.new target_ip
    if @connections.is_there_connection?(target.host)
      conn = @connections.get_connection(target.host)
    else
      conn = Bolt::Transport::SSH::Connection.new target
      conn.connect
      @connections.add_connection(conn)
    end
    puts target_ip, script
    conn.running_as('root') do
      conn.with_remote_tempdir do |dir|
        remote_path = conn.write_remote_executable(dir, script)
        dir.chown(conn.run_as)
        puts dir, remote_path
        output = conn.execute([remote_path, nil], sudoable: true)
        send_result(output,sender_addrinfo[2])
      end
    end 
  end 
end 

