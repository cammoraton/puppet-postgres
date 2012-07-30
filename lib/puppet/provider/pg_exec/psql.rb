Puppet::Type.type(:pg_exec).provide(:psql) do

  desc 'Provider to add, delete, manipulate postgres databases.'
  
  commands :psql => '/usr/bin/psql'

  # This is the only thing here.
  def run
    basecmd = []
    basecmd << command(:psql)
    basecmd << "-U" unless @resource[:role].nil?
    basecmd << "#{@resource[:role]}" unless @resource[:role].nil?
    basecmd << "-d" unless @resource[:database].nil?
    basecmd << "#{@resource[:database]}" unless @resource[:database].nil?
    
    # We execute by default.
    execute = true
    unless @resource[:query].nil?
      cmd = basecmd
      cmd << '-qAtc'
      
      sqlcmd = "#{@resource[:query]}"
      
      cmd << sqlcmd
      
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
      if status == 0
        execute = false # Got an ok result, so we'll evaluate.

        if ! @resource[:rows].nil?
          target_rows   = Integer(@resource[:rows].gsub(/[^\d]/,''))
          operand = @resource[:rows].gsub(/[\d]/,'').chomp.downcase
          returned_rows = (raw.length <= 0 ? 0 : raw.lines.count)
          if operand.match(/lte|less than or equal|<=/)
            execute = true if returned_rows <= target_rows
          elsif operand.match(/gte|greater than or equal|>=/)
            execute = true if returned_rows >= target_rows
          elsif operand.match(/lt|less than|</)
            execute = true if returned_rows < target_rows 
          elsif operand.match(/gt|greater than|>/)
            execute = true if returned_rows > target_rows
          else
            execute = true if returned_rows == target_rows
          end
        end
      else
        # We stop an execution if rows or result params are set
        # on the assumption that if you want to evaluate against criteria like those
        # you want to actually do so.
        execute = false if (! @resource[:rows].nil? or ! @resource[:result].nil?)
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
        # Right now we send a warning.  This should still trigger a refresh if you
        # want to use queries to conditionally do things for some insane reason.
        self.warning("Nothing to do.")
      end
      
      raw, status = Puppet::Util::SUIDManager.run_and_capture(cmd, 'postgres')
      if status != 0
        self.fail("Error executing SQL - result #{raw}")
      else
        @ran = true
      end
    else
      self.fail("Execution criteria failed.  Failing to prevent dependant resources from executing.")
    end
  end
  
end
  
  