module Puppet
  newtype(:pg_exec) do
    @doc = "Execute SQL commands on a postgresql server.
    
    This has a number of different behaviors depending on which parameters are set.
    
    Refreshonly behaves as it does for the exec type.  If set to true then this only does
    anything if a dependant resource is modified.
    
    The next bit depends on a few factors:
    - If query is set then it will query the SQL server as the user specified.
      - If result is set then it will attempt to match the query to the provided expression and only execute
        the command if it finds a match.
      - If rows is set then it will execute if the number of rows returned from the query meets the criteria
      - If neither of the above 2 are set, then it will execute if the PSQL command returns any code except 0.
    - If the above conditions are met for an execution it will then execute the psql command
      - If command is set, it will do a psql -qAtc :command
      - If file is set, it will do a psql -qAtf :file
    - If neither a command or a file are set, it will simply refresh.  You could use this, potentially, to
      trigger other resources to run on the basis of DB queries.
    - This defaults to a naked execution as the postgres user, but user and database can be specified.
    
    Like the exec type it inherits refreshonly from - be very, very careful with this.  
    It's mainly included in order to be able do things like load a default dataset or install postgres plugins 
    immediately post-server installation, or immediately after setting up a new database, 
    with the query used as an extra layer of protection against accidental refreshes
    (IE: you change the DB ACL or owner). "

    newparam(:name) do
      desc "Name identifier of this SQL exec. This value needs to be unique."
      isnamevar
    end


    newparam(:database) do
      desc "Database to execute and evaluate against."
    end
    
    newparam(:role) do
      desc "Role to run the command as.  This is equivalent to connecting over local socket
      as that role"
    end
    
    newparam(:query) do
      desc "Query to run to determine if we should execute our command or not"
      
      munge do |value|
        if value.is_a? Array
          value.each{|val| val.chomp!}.each{|val| val.chop! if val.end_with?(';')}.join('; ') << ';'
        elsif value.is_a? String
          value.chomp!
          value << ';' if ! value.end_with?(';')
          value
        else
           raise ArgumentError "Query property must be an array or string."
        end
      end
    end
    
    newparam(:rows) do
      desc "Number of rows that if returned will trigger the command.  Is additive with result.
      
      Accepts a string which should contain a number and can contain the following operations:
        <=  less than or equal to      lte
        <   less than                  lt
        >=  greater than or equal to   gte
        >   greater than               gt
        
      If no operand is set, defaults to equals(==). 
      
      The number of returned rows is evaluated against the expression."
    end
    
    newparam(:file) do
      desc "Execute SQL command(s) out of a file.  Useful for plugins which place install sql"
      
      # Check for the file
      validate do |value|
        if ! FileTest.exists?(value)
          raise Puppet::Error, "Puppet::Type::Pg_Exec: file #{value} does not exist."
        end
      end
    end
    
    newparam(:command) do
      desc "Raw SQL to run."
      
      munge do |value|
        if value.is_a? Array
          value.each{|val| val.chomp!}.each{|val| val.chop! if val.end_with?(';')}.join('; ') << ';'
        elsif value.is_a? String
          value.chomp!
          value << ';' if ! value.end_with?(';')
          value
        else
          raise ArgumentError "Command must be an array or string."
        end
      end
  
    end
    
    newparam(:result) do
      desc "Regex to match result of query against"
      
    end
    
    newproperty(:status) do
      # We default to a value here so that this triggers
      defaultto :run
      
       # Make output a bit prettier
      def change_to_s(currentvalue, newvalue)
        return "completed successfully."
      end
      
      # First verify that all of our checks pass.
      def retrieve
        if @resource.check_all_attributes
          return :notrun
        else
          return self.should
        end
      end
      
      def sync
        provider.run
      end
    end
    
    # Autorequirements - Really basic right now
    autorequire(:pg_database) do
      self[:database]
    end
     
    autorequire(:pg_role) do
      self[:role]
    end
     
    autorequire(:file) do
      self[:file]
    end
    
    # Require the postgres service
    autorequire(:service) do
      [ "postgres", "postgresql" ]
    end
    
    # The following was pulled out of Puppet::Exec in order to provide refreshonly as an option.
    # Every time this resource refreshes it queries the database, so you probably want to be able
    # to confine that behavior via that mechanism.
        
    # Create a new check mechanism.  It's basically just a parameter that
    # provides one extra 'check' method.
    def self.newcheck(name, options = {}, &block)
      @checks ||= {}

      check = newparam(name, options, &block)
      @checks[name] = check
    end

    def self.checks
      @checks.keys
    end
    
    newcheck(:refreshonly) do
      desc "The command should only be run as a
        refresh mechanism for when a dependent object is changed."

      newvalues(:true, :false)

      # We always fail this test, because we're only supposed to run
      # on refresh.
      def check(value)
        # We have to invert the values.
        if value == :true
          false
        else
          true
        end
      end
    end
    
    # Verify that we pass all of the checks.  The argument determines whether
    # we skip the :refreshonly check, which is necessary because we now check
    # within refresh
    def check_all_attributes(refreshing = false)
      self.class.checks.each { |check|
        next if refreshing and check == :refreshonly
        if @parameters.include?(check)
          val = @parameters[check].value
          val = [val] unless val.is_a? Array
          val.each do |value|
            return false unless @parameters[check].check(value)
          end
        end
      }

      true
    end

    # Run the command
    def refresh
      if self.check_all_attributes(true)
        provider.run
      end
    end
  end
end
