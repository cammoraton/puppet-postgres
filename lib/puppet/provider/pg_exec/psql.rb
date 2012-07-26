Puppet::Type.type(:pg_exec).provide(:psql) do

  desc 'Provider to add, delete, manipulate postgres databases.'
  
  commands :psql => '/usr/bin/psql'
  commands :pgrep => '/usr/bin/pgrep'
  
  def run
    basecmd = []
    basecmd << command(:psql)
    basecmd << "-U #{@resource[:role]}" unless @resource[:role].nil?
    basecmd << "-d #{@resource[:database]}" unless @resource[:database].nil?
    
    raw = nil
    execute = true
    unless @resource[:query].nil?
      cmd = basecmd
      cmd << '-qAtc'
      
      sqlcmd = "#{@resource[:query]}"
      
      cmd << sqlcmd
      
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
      warning("Got #{status} and #{raw}")
      if status == 0
        unless @resource[:result].nil?
        # Compare raw to the regex and modify execute
          execute = false
        else
          execute = false
        end
      end
    end
    
    unless execute == false
      cmd = basecmd
      if ! @resource[:command].nil?
        cmd << '-qAtc'
        
        sqlcmd = "#{@resource[:command]}"
        
        cmd << sqlcmd   
      elsif ! @resource[:file].nil?
        cmd << '-qAtf'
        
        sqlcmd = "#{@resource[:file]}"
        
        cmd << sqlcmd
      else
        self.fail("Nothing to do.")
      end
      
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
      warning("Got #{status} and #{raw}")
      if status != 0
        self.fail("Error executing SQL - result #{raw}")
      else
        @ran = true
      end
    end
  end
  
end
  