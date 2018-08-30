require 'bolt/error'

# Uploads the given file or directory to the given set of targets and returns the result from each upload.
#
# * This function does nothing if the list of targets is empty.
# * It is possible to run on the target 'localhost'
# * A target is a String with a targets's hostname or a Target.
# * The returned value contains information about the result per target.
#
Puppet::Functions.create_function(:file_upload, Puppet::Functions::InternalFunction) do
  dispatch :file_upload do
    scope_param
    param 'String[1]', :source
    param 'String[1]', :destination
    param 'Boltlib::TargetSpec', :targets
    optional_param 'Hash[String[1], Any]', :options
    return_type 'ResultSet'
  end

  def file_upload(scope, source, destination, targets, options = nil)
    options ||= {}
    unless Puppet[:tasks]
      raise Puppet::ParseErrorWithIssue.from_issue_and_stack(
        Puppet::Pops::Issues::TASK_OPERATION_NOT_SUPPORTED_WHEN_COMPILING, operation: 'file_upload'
      )
    end

    executor = Puppet.lookup(:bolt_executor) { nil }
    inventory = Puppet.lookup(:bolt_inventory) { nil }
    unless executor && inventory && Puppet.features.bolt?
      raise Puppet::ParseErrorWithIssue.from_issue_and_stack(
        Puppet::Pops::Issues::TASK_MISSING_BOLT, action: _('do file uploads')
      )
    end

    found = Puppet::Parser::Files.find_file(source, scope.compiler.environment)
    unless found && Puppet::FileSystem.exist?(found)
      raise Puppet::ParseErrorWithIssue.from_issue_and_stack(
        Puppet::Pops::Issues::NO_SUCH_FILE_OR_DIRECTORY, file: source
      )
    end

    # Ensure that that given targets are all Target instances
    targets = inventory.get_targets(targets)
    if targets.empty?
      call_function('debug', "Simulating file upload of '#{found}' - no targets given - no action taken")
      r = Bolt::ResultSet.new([])
    else
      r = executor.file_upload(targets, found, destination, options.select { |k, _| k == '_run_as' })
    end

    if !r.ok && !options['_catch_errors']
      raise Bolt::RunFailure.new(r, 'upload_file', source)
    end
    r
  end
end
