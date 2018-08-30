
require 'bolt/connections_pool/base' 

class Connections_pool < Base 
  attr_reader :sessions

  def initialize
      super
      @connections =  Hash.new
  end

  def add_connection(connection)
      @connections[connection.session.host.hash]=connection
  end

  def get_connection(host)
      return @connections[host.hash]
  end

  def is_there_connection?(host)
      return @connections.has_key?(host.hash)
  end
end


