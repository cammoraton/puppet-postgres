module Puppet
  newtype(:pg_role) do
    @doc = "Type for manipulating postgres users."

    ensurable

    newparam(:name) do
      desc "Name of this role. This value needs to be unique and can not contain commas or pipes."
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
      # Add validation here, this should be an number
      defaultto '-1'
    end

    newproperty(:groups) do
      desc "An array of roles that the role is a member of.  Be careful mixing use of this with members as they are evaluated seperately."
      
      validate do |value|
        raise Puppet::Error, "Puppet::Type::Pg_Role: groups property must be an array." unless value.is_a? Array
      end

      defaultto Array.new
    end
    
    newproperty(:members) do
      desc "An array of roles that are a member of this role.  Be careful mixing use of this with groups as they are evaluated seperately."
      
      validate do |value|
        raise Puppet::Error, "Puppet::Type::Pg_Role: members property must be an array." unless value.is_a? Array
      end

      defaultto Array.new
    end
  end
end