require 'puppet/provider/postgres'
# The difference between a user and group these days
# is if pg_catalog.pg_roles.rolcanlogin is set to true or false
# so we use a single provider to handle both users and groups.
Puppet::Type.type(:pg_exec).provide(:psql, :parent => Puppet::Provider::Postgres) do
  desc 'Provider to execute sql commands on the basis of the result of a query'
  
  commands :psql => '/usr/bin/psql'
  
  # We don't do anything with instances for this.
  def self.instances
    
    block_until_ready

  end
  
  # or Prefetch
  def self.prefetch(resources)
    
  end
  
  # We always exist
  def exists?
    true
  end
  
  # Getters.  Apart from our query, they always equal the resource
  def database
    @resource[:database]
  end
  
  def query
    @resource[:query]
  end
  
  def user
    @resource[:user]
  end
  
  def exec
    @resource[:exec]
  end
  
  def type
    @resource[:type]
  end
  
  def evaluates
    # We execute the actual query here.
    cmd = []
    cmd << command(:psql)
    cmd << '-qAtc'
    cmd << @resource[:query]
    cmd << @resource[:database] unless @resource[:database].nil?
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, @resource[:user])

    if status == 0
      return :true
    else 
      return :false
    end
  end
  
  def database=(should)
    @property_hash[:database] = should
  end
  
  def evaluates=(should)
    @property_hash[:evaluates] = should
  end
  
  def query=(should)
    @property_hash[:query] = should
  end
  
  def user=(should)
    @property_hash[:user] = should
  end
  
  def exec=(should)
    @property_hash[:exec] = should
  end
  
  def type=(should)
    @property_hash[:type] = should
  end
  
  # Should never be called
  def create
    @property_hash = {
      :name     => @resource[:name],
      :database => @resource[:database],
      :evaluates  => @resource[:evaluates],
      :user     => @resource[:user],
      :query    => @resource[:query],
      :exec     => @resource[:exec],
      :type     => @resource[:type],
      :ensure   => :present
    }
  end
  
  # Also should never be called
  def destroy
    @property_hash.clear
  end
  

  
  # Flush gets triggered if evaluates value is something other than what you're expecting
  def flush
   unless @property_hash.empty?
      cmd = []
      cmd << command(:psql)
      case @resource[:type]
       when :sql
         cmd << '-qAtc'
       when :file
         cmd << '-qAtf'
       else
         fail("Unknown type #{@resource[:type]}")
      end  
      cmd << @resource[:exec]      
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, @resource[:user])

      if status != 0
        fail("Error executing command - #{raw}")
      end
    end
  end
  
end
