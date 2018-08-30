require 'bolt/connections_pool/connections_pool'

class Connections
  def initialize(connections_pool)
    @connections_pool = connections_pool
  end

  def add_connection(connection)
    return @connections_pool.add_connection(connection)
  end

  def remove_connection(connection)
    return @connections_pool.remove_connection(connection)
  end

  def get_connection(host)
    return @connections_pool.get_connection(host) 
  end

  def is_there_connection?(host)
    return @connections_pool.is_there_connection?(host)
  end
end
