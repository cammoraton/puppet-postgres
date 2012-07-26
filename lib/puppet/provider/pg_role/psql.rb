require 'puppet/provider/postgres'
# The difference between a user and group these days
# is if pg_catalog.pg_roles.rolcanlogin is set to true or false
# so we use a single provider to handle both users and groups.
Puppet::Type.type(:pg_role).provide(:psql, :parent => Puppet::Provider::Postgres) do
  desc 'Provider to add, delete, manipulate postgres roles.'
  
  commands :psql => '/usr/bin/psql'
  def self.instances
    
    block_until_ready
    
    instances = []
    # This is the equivalent of a \du, except we get a lot more information(like members), in a format
    # we like.
    sqlcmd = "SELECT r.rolname, r.rolsuper, r.rolinherit,
                     r.rolcreaterole, r.rolcreatedb, r.rolconnlimit, r.rolcanlogin,
                     ARRAY(SELECT b.rolname
                           FROM pg_catalog.pg_auth_members m
                           JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid)
                           WHERE m.member = r.oid) as memberof,
                     ARRAY(SELECT b.rolname
                           FROM pg_catalog.pg_auth_members m
                           JOIN pg_catalog.pg_roles b on (m.member = b.oid)
                           WHERE m.roleid = r.oid) as members
              FROM pg_catalog.pg_roles r
              ORDER BY 1;"
    cmd = []
    cmd << command(:psql)
    # quiet, unaligned output, tuples only, execute command
    cmd << '-qAtc'
    cmd << sqlcmd 
    
    # Run as the postgres user.  This and the cmd should be configurable probably
    # but it's pretty standard
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')

    # Parse out the users
    raw.split(/\n\r|\n|\r\n/).uniq.each do |user|
      values = user.split('|')
      # Initialize to blank arrays
      groups = []
      members = []
      # Remove the brackets(chop off trailing and leading characters)
      groups  = values[7][1..-2].split(',') unless values[7].length <= 2
      members = values[8][1..-2].split(',') unless values[8].length <= 2

      role_instance = { :name        => values[0],
                        :superuser   => ( values[1].match('t') ? :true : :false ),
                        :inherits    => ( values[2].match('t') ? :true : :false ),
                        :createrole  => ( values[3].match('t') ? :true : :false ),
                        :createdb    => ( values[4].match('t') ? :true : :false ),
                        :connlimit   => values[5],
                        :login       => ( values[6].match('t') ? :true : :false ),
                        :groups      => groups.sort,
                        :members     => members.sort,
                        :provider    => self.name }
      instances << new(role_instance)
    end
    instances
  end
    
  # Getters - Retrieve values from the instances
  def superuser
    @property_hash[:superuser]
  end

  def inherits
    @property_hash[:inherits]
  end
  
  def createrole
    @property_hash[:createrole]
  end
  
  def createdb
    @property_hash[:createdb]
  end
  
  def connlimit
    @property_hash[:connlimit]
  end
  
  def login
    @property_hash[:login]
  end
  
  def groups
    @property_hash[:groups]
  end
  
  def members
    @property_hash[:members]
  end
  
  # We bypass the property_hash here to make sure this never triggers a change.
  def password
    @resource[:password].nil? ? nil : @resource[:password]
  end

  # Setters - These should only be called when the resource already exists.
  def superuser=(should)
    @property_hash[:superuser] = should
  end

  def inherits=(should)
    @property_hash[:inherits] = should
  end
  
  def createrole=(should)
    @property_hash[:createrole] = should
  end
  
  def createdb=(should)
    @property_hash[:createdb] = should
  end
  
  def connlimit=(should)
    @property_hash[:connlimit] = should
  end
  
  def login=(should)
    @property_hash[:login] = should
  end
  
  # These two are... odd.
  # We need to keep track of what things originally were so we can do
  # revokes or grants as the case may be
  def groups=(should)
    @original_groups = []
    @original_groups = @property_hash[:groups] unless @property_hash[:groups].nil? or @property_hash[:groups].empty?
    @property_hash[:groups] = should.sort
  end
  
  def members=(should)
    @original_members = []
    @original_members = @property_hash[:members] unless @property_hash[:members].nil? or @property_hash[:members].empty?
    @property_hash[:members] = should.sort
  end
  
  # This should basically never get used.
  def password=(should)
    @property_hash[:password] = should
  end
  
  def create
    @property_hash = {
      :name       => @resource[:name],
      :superuser  => @resource[:superuser],
      :inherits   => @resource[:inherits],
      :createrole => @resource[:createrole],
      :createdb   => @resource[:createdb],
      :connlimit  => @resource[:connlimit],
      :login      => @resource[:login],
      :members    => [],
      :groups     => [],
      :ensure     => :present
    }
    @property_hash[:groups]  = @resource[:groups]  if ! @resource[:groups].nil?
    @property_hash[:members] = @resource[:members] if ! @resource[:members].nil?
    
    cmd = []
    cmd << command(:psql)
    cmd << '-qAtc'
    sqlcmd = "CREATE ROLE #{@property_hash[:name]}"
    sqlcmd << " WITH PASSWORD '#{@resource[:password]}'" unless @resource[:password].nil?
    sqlcmd << ";"
    cmd << sqlcmd
    # We create the actual role here(with password, if set) and settings will be applied during the flush.
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
  end
  
  def destroy
    cmd = []
    cmd << command(:psql)
    cmd << '-qAtc'
    cmd << "DROP ROLE #{@property_hash[:name]};"
    
    # We just drop the thing.
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
    @property_hash.clear
  end
  
  # Flush is triggered on anything that has been detected as being
  # modified in the property_hash.
  def flush
    unless @property_hash.empty?
      cmd = []
      cmd << command(:psql)
      cmd << '-qAtc'
      updated = ''
      updated << "ALTER ROLE #{@property_hash[:name]} "
      updated << (@property_hash[:superuser]  == :true ? 'SUPERUSER'  : 'NOSUPERUSER')  << ' ' unless @property_hash[:superuser].nil?
      updated << (@property_hash[:createdb]   == :true ? 'CREATEDB'   : 'NOCREATEDB')   << ' ' unless @property_hash[:createdb].nil?
      updated << (@property_hash[:createrole] == :true ? 'CREATEROLE' : 'NOCREATEROLE') << ' ' unless @property_hash[:createrole].nil?
      updated << (@property_hash[:inherits]   == :true ? 'INHERIT'    : 'NOINHERIT')    << ' ' unless @property_hash[:inherits].nil?
      updated << (@property_hash[:login]      == :true ? 'LOGIN'      : 'NOLOGIN')      << ' ' unless @property_hash[:login].nil?
      updated << "CONNECTION LIMIT #{@property_hash[:connlimit]}; "
      # Right now we can only Grant, because I do not know how to
      # get the original values to determine what should be granted and what should change
      # instances would work, but that requeries the database and that seems wasteful as hell.
      # And revoke all then a regrant might cause problems.
      unless @property_hash[:groups].empty?
        warning("Groups: #{@property_hash[:groups]}")
        @property_hash[:groups].each do |grp|
          updated << "GRANT #{grp} TO #{@property_hash[:name]}; "
        end
      end
      unless @property_hash[:members].empty?
        @property_hash[:members].each do |mem|
          updated << "GRANT #{@property_hash[:name]} TO #{mem}; "
        end    
      end
      cmd << updated
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
    end
  end 
end