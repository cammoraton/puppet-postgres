Puppet::Type.type(:pg_exec).provide(:psql) do

  desc 'Provider which executes SQL commands'
  
  commands :psql => '/usr/bin/psql'
  
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
      
      # We assume that a failure code means something like function or table
      # doesn't exist.
      if status == 0
        execute = false
        # Right now these two always fail.
        if ! @resource[:result].nil?
          # Compare raw to the regex and modify execute
          execute = false
        end
        
        if ! @resource[:rows].nil?
          # Check the number of rows against that parameter
          execute = false
        end
      end
    end
    
    unless execute == false
      cmd = basecmd
      if ! @resource[:command].nil?
        # Quiet, tuples only, no echo back command, execute command
        cmd << '-qAtc'
        
        sqlcmd = "#{@resource[:command]}"
        
        cmd << sqlcmd   
      elsif ! @resource[:file].nil?
        # Quiet, tuples, no echo back command, file
        cmd << '-qAtf'  
        
        sqlcmd = "#{@resource[:file]}"
        
        cmd << sqlcmd
      else
        self.fail("Nothing to do.")
      end
      
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
      if status != 0
        self.fail("Error executing SQL - result #{raw}")
      else
        @ran = true  # Set ran to true for status message prettiness
      end
    end
  end
  
end
  