require 'net/ssh'
require 'bolt/node/errors'
require 'bolt/node/output'
require 'bolt/error'
require 'logging'

class Connection
  attr_reader :logger, :user, :target
  attr_writer :run_as
  def initialize(target)
    @target = target
    @user = @target.user
    @logger = Logging.logger[@target.host]
  end

  def connect
    #transport_logger = Logging.logger[Net::SSH]
    #transport_logger.level = :warn
    options = {
      #logger: transport_logger,
      non_interactive: true,
      config: true
    }

    options[:port] = @target.port if @target.port
    options[:password] = @target.password if @target.password
    options[:verify_host_key] = if @target.options['host-key-check']
                                  Net::SSH::Verifiers::Secure.new
                                else
                                  Net::SSH::Verifiers::Lenient.new
                                end
    options[:timeout] = @target.options['connect-timeout'] if @target.options['connect-timeout']
    @session = Net::SSH.start(@target.host, @user, options)
  rescue Net::SSH::AuthenticationFailed => e
  raise Bolt::Node::ConnectError.new(
    e.message,
    'AUTH_ERROR'
  )
  rescue Net::SSH::HostKeyError => e
    raise Bolt::Node::ConnectError.new(
      "Host key verification failed for #{@target.uri}: #{e.message}",
      'HOST_KEY_ERROR'
    )
  rescue Net::SSH::ConnectionTimeout
    raise Bolt::Node::ConnectError.new(
      "Timeout after #{@target.options['connect-timeout']} seconds connecting to #{@target.uri}",
      'CONNECT_ERROR'
    )
  rescue StandardError => e
    raise Bolt::Node::ConnectError.new(
      "Failed to connect to #{@target.uri}: #{e.message}",
      'CONNECT_ERROR'
    )
  end

  def disconnect
    if @session && !@session.closed?
      @session.close
      @logger.debug { "Closed session" }
    end
  end

  def execute(command, sudoable: false, **options)
    result_output = Bolt::Node::Output.new
    run_as = options[:run_as] || self.run_as
    use_sudo = sudoable && run_as && @user != run_as

    command_str = command.is_a?(String) ? command : Shellwords.shelljoin(command)
    if use_sudo
      sudo_str = Shellwords.shelljoin(["sudo", "-S", "-u", run_as, "-p", sudo_prompt])
      command_str = "#{sudo_str} #{command_str}"
    end

    # Including the environment declarations in the shelljoin will escape
    # the = sign, so we have to handle them separately.
    if options[:environment]
      env_decls = options[:environment].map do |env, val|
        "#{env}=#{Shellwords.shellescape(val)}"
      end
      command_str = "#{env_decls.join(' ')} #{command_str}"
    end

    @logger.debug { "Executing: #{command_str}" }

    session_channel = @session.open_channel do |channel|
      # Request a pseudo tty
      channel.request_pty if target.options['tty']
    
      channel.exec(command_str) do |_, success|
        unless success
          raise Bolt::Node::ConnectError.new(
            "Could not execute command: #{command_str.inspect}",
            'EXEC_ERROR'
          )
        end
    
        channel.on_data do |_, data|
          unless use_sudo && handled_sudo(channel, data)
            result_output.stdout << data
          end
          @logger.debug { "stdout: #{data}" }
        end
        channel.on_request("exit-status") do |_, data|
          result_output.exit_code = data.read_long
        end

        if options[:stdin]
          channel.send_data(options[:stdin])
          channel.eof!
        end
      end
    end
    session_channel.wait

    if result_output.exit_code == 0
      @logger.debug { "Command returned successfully" }
    else
      @logger.info { "Command failed with exit code #{result_output.exit_code}" }
    end
    result_output
  end
end

