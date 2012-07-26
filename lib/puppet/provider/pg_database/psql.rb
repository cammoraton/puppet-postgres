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
      values = database.split('|')
      if ! values[2].nil? and values[2].is_a? String and values[2].length > 2
        values[2][1..-2].split(',').each do |acl|
          vals = acl.split('/').first.split('=')
          if ! vals.first.nil? and vals.first.length > 0
            create    = ( vals.last.match(/C/) ? true : false )
            connect   = ( vals.last.match(/c/) ? true : false )
            temporary = ( vals.last.match(/T/) ? true : false )
            # We're not doing anything with these yet.
          end
        end
      end
      # Need to translate datacl to english
      database_instance = { :name      => values[0],
                            :owner     => values[1],
# We don't do anything with the access hash right now
#                            :access    => values[5],
                            :provider  => self.name }
      instances << new(database_instance)
    end

    instances
  end
  
  # We get the owner from the property hash which should be pre-populated via instances.
  def owner
    @property_hash[:owner]
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
    # We create the actual database here.  Ownership will be flipped via an alter on the flush.
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')   
    if status != 0
      fail("Error creating database - #{raw}")
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
      fail("Error dropping database - #{raw}")
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
      
      database = ( @property_hash[:name].downcase != @property_hash[:name] ? "\"#{@property_hash[:name]}\"" : @property_hash[:name] )
      
      sqlcmd = ""
      
      unless @property_hash[:owner].nil?
        owner = ( @property_hash[:owner].downcase != @property_hash[:owner] ? "\"#{@property_hash[:owner]}\"" : @property_hash[:owner]) 
        sqlcmd << "ALTER DATABASE #{database} OWNER TO #{owner};"
      end

      # Run through the ACL and make changes via GRANT and REVOKE.
      
      cmd << sqlcmd
      # And execute
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
      if status != 0
        fail("Error updating database - #{raw}")
      end
    end
  end
end
