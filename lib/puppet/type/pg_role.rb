module Puppet
  newtype(:pg_role) do
    @doc = "Type for manipulating postgres users."

    ensurable

    newparam(:name) do
      desc "Name of this role. This value needs to be unique and can not contain commas or pipes."
      
      
      
      # Need to do validation.
      isnamevar
    end
    
    newproperty(:superuser) do
      desc "Superuser.  A boolean value that determines if the role is a super user.
            Defaults to false when a role is created, but has no default value here.
            
            If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:inherits) do
      desc "Inherits.  A boolean value that determines if the role can inherit permissions
            from roles it is a member of.  Defaults to true in postgres, but has no default value here.
            
            If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:createrole) do
      desc "Create role.  A boolean value that determines if the role can create other roles.
            Defaults to false in postgres, but has no default value here. 
            
            If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:createdb) do
      desc "Create database.  A boolean value that determines if the role can create new databases.
            Defaults to false, but has no default value here.  
            
            If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:login) do
      desc "Login.  A boolean value that determines if the role can log in or not.  This property
            is the dividing line between users and groups, users can log in, groups can not.  Defaults
            to true, but has no default value here.  
            
            If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:password) do
      desc "Password.  Only set on create."
    end
    
    newproperty(:connlimit) do
      desc "Connection limit.  -1 for none"
      # Add validation here, this should be a number
      defaultto '-1'
    end

    # We should probably do some autorequires, but....
    newproperty(:groups, :array_matching => :all) do
      desc "An array of roles that the role is a member of. 
      This is case sensitive and the back-end queries will automatically enclose anything containing uppercase letters
        or spaces in quotes.
        
      Be careful mixing use of this with members as they are evaluated seperately."
 
      def should=(value)
        super
        if value.is_a? Array
          @should.sort!  # Sort these because order in no way matters.
        else
          # Need to redo this so it creates a new array if value is a string.
          raise Puppet::Error, "Puppet::Type::Pg_Role: groups property must be an array."
        end
      end
      # Should probably do an autorequire here.
      defaultto Array.new
    end
    
    # We should probably do some autorequires, but....
    newproperty(:members, :array_matching => :all) do
      desc "An array of roles that are a member of this role.  
      This is case sensitive and the back-end queries will automatically enclose anything containing uppercase letters
        or spaces in quotes.
      
      Be careful mixing use of this with groups as they are evaluated seperately."

      def should=(value)
        super
        if value.is_a? Array
          @should.sort! # Sort these because order in no way matters.
        else
          # Need to redo this so it creates a new array if value is a string.
          raise Puppet::Error, "Puppet::Type::Pg_Role: members property must be an array."
        end
      end
      
      # Should probably do an autorequire here.
       
      defaultto Array.new
    end
  end
end