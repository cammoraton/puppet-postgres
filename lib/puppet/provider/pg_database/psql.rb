require 'puppet/provider/postgres'
Puppet::Type.type(:pg_database).provide(:psql, :parent => Puppet::Provider::Postgres) do

  desc 'Provider to add, delete, manipulate postgres databases.'
  
  commands :psql => '/usr/bin/psql'
  commands :pgrep => '/usr/bin/pgrep'
  
  def self.instances
    
    block_until_ready
    
    instances = []
    # This is equivalent to a \l but cleaner format.
    sqlcmd = "SELECT d.datname, r.rolname, d.datacl
              FROM pg_catalog.pg_database d
              JOIN pg_catalog.pg_roles r 
              ON r.oid = d.datdba;"
    cmd = []
    cmd << command(:psql)
    # queit, unaligned output, tuples only, execute command
    cmd << '-qAtc'
    cmd << sqlcmd
    # Run as the postgres user.  This and the cmd should be configurable probably
    # but it's pretty standard
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
    if status != 0
      self.fail("Error retrieving databases - #{raw}")
    end
    # Parse out the databases

    raw.split(/\n\r|\n|\r\n/).uniq.each do |database|
      access = {}
      values = database.split('|')
      if ! values[2].nil? and values[2].is_a? String and values[2].length > 2
        values[2][1..-2].split(',').each do |acl|
          vals = acl.split('/').first.split('=')
          if ! vals.first.nil? and vals.first.length > 0
            access[vals.first.to_sym] = { :connect   => ( vals.last.match(/c/) ? :true : :false ),
                                          :create    => ( vals.last.match(/C/) ? :true : :false ),
                                          :temporary => ( vals.last.match(/T/) ? :true : :false ) }
          end
        end
      end

      database_instance = { :name      => values[0],
                            :owner     => values[1],
                            :access    => access,
                            :provider  => self.name }
      instances << new(database_instance)
    end

    instances
  end
  
  # We get the owner from the property hash which should be pre-populated via instances.
  def owner
    @property_hash[:owner]
  end
  
  def access
    @property_hash[:access]
  end
  
  # The next 3 always return whatever the resource value is
  # since changing the encoding on a database after creation
  # is dangerous enough that you probably shouldn't be doing it
  # with puppet.
  def encoding
    @resource[:encoding].nil? ? nil : @resource[:encoding]
  end
  
  def collate
    @resource[:collate].nil? ? nil : @resource[:collate]
  end
  
  def ctype
    @resource[:ctype].nil? ? nil : @resource[:ctype]
  end
  
  # Setters if the resource already exists. 
  # Basically, you can only change the owner and manipulate the ACL
  def owner=(should)
    @property_hash[:owner] = should
  end
  
  def access=(should)
    # Need to set an original_access variable when we modify the access hash so
    # we can determine what changed.
    @original_access = @property_hash[:access]
    @property_hash[:access] = should
  end
  
  # I'm just standardizing on including these.  They should never trigger a flush.
  def encoding=(should)
    @property_hash[:encoding] = should
  end

  def collate=(should)
    @property_hash[:collate] = should
  end
  
  def ctype=(should)
    @property_hash[:ctype] = should
  end
  
  def create
    @property_hash = {
      :name => @resource[:name],
      :owner => @resource[:owner],
      :ensure => :present
    }
    @property_hash[:access] = @resource[:access] if ! @resource[:access].nil? and ! @resource[:access].empty?
    cmd = []
    cmd << command(:psql)
    cmd << '-qAtc'
    
    database = ( @property_hash[:name].downcase != @property_hash[:name] ? "\"#{@property_hash[:name]}\"" : @property_hash[:name] )
    
    sqlcmd = "CREATE DATABASE #{database}"
    sqlcmd << " ENCODING '#{@resource[:encoding]}'" unless @resource[:encoding].nil?
    sqlcmd << " LC_COLLATE '#{@resource[:collate]}'" unless @resource[:collate].nil?
    sqlcmd << " LC_CTYPE '#{@resource[:ctype]}'" unless @resource[:ctype].nil?
    sqlcmd << ";"

    cmd << sqlcmd
    # We create the actual database here.  Ownership and access will be flipped via an alter on the flush.
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')   
    if status != 0
      self.fail("Error creating database - #{raw}")
    end
  end
  
  def destroy
    cmd = []
    cmd << command(:psql)
    cmd << '-qAtc'
    cmd << "DROP DATABASE #{@property_hash[:name]};"
    
    # Just drop the thing.
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
    if status != 0
      self.fail("Error dropping database - #{raw}")
    end
    @property_hash.clear
  end
  
  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash. It generates a temporary file with
  # the updates that need to be made. The temporary file is then used
  # as stdin for the psql command.
  def flush
    unless @property_hash.empty?
      cmd = []
      cmd << command(:psql)
      cmd << '-qAtc'
      
      # Enclose database name in quotes if necessary(contains whitespace or uppercase letters)
      database = (((@property_hash[:name].downcase != @property_hash[:name]) or
                   (@property_hash[:name].match(/\s/))) ? "\"#{@property_hash[:name]}\"" : @property_hash[:name] )
      
      sqlcmd = ""
      
      unless @property_hash[:owner].nil?
        # Enclose owner in quotes if necessary(contains whitespace or uppercase letters)
        owner = (((@property_hash[:owner].downcase != @property_hash[:owner]) or 
                  (@property_hash[:owner].match(/\s/))) ? "\"#{@property_hash[:owner]}\"" : @property_hash[:owner]) 
        sqlcmd << "ALTER DATABASE #{database} OWNER TO #{owner}; "
      end

      # Run through the ACL and make changes via GRANT and REVOKE.
      unless @property_hash[:access].empty?
        # Hash for all our revokes
        revoke = Hash.new
        # Hash for all our grants
        grant = Hash.new
        
        # Figure out what to grant and what to revoke
        if @original_access and ! @original_access.empty?
          @original_access.each_key do |role|
            # Does the key exist in the new property hash?
            if @property_hash[:access].has_key?(role)
              revoke[role] = Hash.new
              grant[role]  = Hash.new
              @original_access[role].each do |key, value|
                # Did we flip something from true to false? or false to true?
                revoke[role][key] = :false if (@property_hash[:access][role][key] == :false and value == :true)
                grant[role][key] = :true if (@property_hash[:access][role][key] == :true and value == :false)
              end 
            else
              # No, revoke the whole role.
              revoke[role] = { :create => :false, :connect => :false, :temporary => :false }
            end
          end
          # Now get what's totally new
          @property_hash[:access].each_key do |role|
            grant[role] = @property_hash[:access][role] if ! @original_access.has_key?(role)
          end
        else
          @property_hash[:access].each_key do |role|
            grant[role] = @property_hash[:access][role]
          end
        end
        # Revoke anything we should revoke
        revoke.each do |r, p|
          # I'm not quite sure why I decided to use a string
          # there had to be a reason, right?
          revoke_segment = ""
          # We need to de-symify for parsing and sql
          # Also enclose in quotes if it contains uppercase or whitespace
          role = (((r.to_s.downcase != r.to_s) or (r.to_s.match(/\s/))) ? "\"#{r}\"" : r.to_s)
          p.each_key do |type|
            case type
            when :connect
                revoke_segment << "CONNECT "
            when :create
                revoke_segment << "CREATE "
            when :temporary 
                revoke_segment << "TEMPORARY "
            end
          end
          if revoke_segment.length > 0
            # Because right here it looks like I could've used an array, evaluated for num elements and just
            # done a join....
            sqlcmd << "REVOKE #{revoke_segment.split(' ').join(', ')} ON DATABASE #{database} FROM #{role}; "
          end
        end
        # Now do the grants
        grant.each do |r, p|         
          # I'm not quite sure why I decided to use a string
          # there had to be a reason, right?
          grant_segment = ""
          # We need to de-symify for parsing and sql
          # Also enclose in quotes if it contains uppercase or whitespace
          role = (((r.to_s.downcase != r.to_s) or (r.to_s.match(/\s/))) ? "\"#{r}\"" : r.to_s)
          p.each do |type,val|
            if val == :true
              case type
              when :connect
                grant_segment << "CONNECT "
              when :create
                grant_segment << "CREATE "
              when :temporary 
                grant_segment << "TEMPORARY "
              end
            end
          end
          if grant_segment.length > 0
            # Because right here it looks like I could've used an array, evaluated for num elements and just
            # done a join....
            sqlcmd << "GRANT #{grant_segment.split(' ').join(', ')} ON DATABASE #{database} TO #{role}; "
          end   
        end
      end
      
      cmd << sqlcmd
      # And execute
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
      if status != 0
        self.fail("Error updating database - #{raw}")
      end
    end
  end
end

