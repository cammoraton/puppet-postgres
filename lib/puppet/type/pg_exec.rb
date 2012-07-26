module Puppet
  newtype(:pg_exec) do
    @doc = "Conditionally execute SQL commands"

    ensurable

    newparam(:name) do
      desc "Name identifier of this database. This value needs to be unique."
      isnamevar
    end
    
    newproperty(:evaluates) do
      desc "Do we execute if the query has a result or doesn't have a result?"
      newvalues(:true, :false)
      defaultto :true
    end
    
    # Default to the postgres user on the postgres database
    newproperty(:user) do
      desc "The user puppet should become to execute the query.  Defaults to postgres."
      defaultto 'postgres'
    end
    
    newproperty(:database) do
      desc "The database puppet should connect to."
      defaultto 'postgres'
    end
    
    newproperty(:query) do
      desc "The query to evaluate.  Returning anything is treated as success."
    end
    
    newproperty(:exec) do
      desc "What to execute.  Either a SQL statment of a file path."
    end

    newproperty(:type) do
      desc "What query is.  Either a SQL statement or a file."
      newvalues(:sql, :file)
      defaultto :sql
    end
  end
end
