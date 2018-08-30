require 'logging'

class Base
  attr_reader :logger

  def initialize
    @logger = Logging.logger[self]
  end

  def add_connection(*_args)
    raise NotImplementedError, "add_connection() must be implemented" 
  end

  def get_connection(*_args)
    raise NotImplementedError, "get_connection() must be implemented"
  end

  def is_there_Connection?(*_args)
    raise NotImplementedError, "is_there_Connection?() must be implemented"
  end
end
