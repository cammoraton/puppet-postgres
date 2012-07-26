class Puppet::Provider::Postgres < Puppet::Provider
  
  # Is postgres running and ready?
   def self.ready?
    cmd = []
    cmd << command(:psql)
    cmd << '-c'
    cmd << '\\echo running'
    # Cheap hack, but I think it's clever.  You can't connect to execute the echo unless
    # postgres is running.
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
    if status == 0
      return true
    else
      return false
    end
  end
  
  # Is there a postgres process?
  def self.started?
    cmd = []
    cmd << command(:pgrep)
    cmd << 'postgres'
    raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd)
    if status == 0
      return true
    else
      return false
    end   
  end
  
  # There can be a delay in starting up postgres.
  def self.block_until_ready(timeout = 120)
    if started?
      Timeout::timeout(timeout) do
        until ready?
         debug('Postgres not ready, retrying')
          sleep 2
        end
      end
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if res = resources[prov.name.to_s]
        res.provider = prov
      end
    end
  end

  def exists?
    self.class.block_until_ready
    debug(@property_hash.inspect)
    !(@property_hash[:ensure] == :absent or @property_hash.empty?)
  end
end