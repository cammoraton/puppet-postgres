module Puppet
  newtype(:pg_role) do
    @doc = "Type for manipulating postgres users."

    ensurable

    newparam(:name) do
      desc "Name of this role. This value needs to be unique and can not contain commas or pipes."
      
      isnamevar
    end
    
    # I had initially set this up as a property, but there just isn't a good way of determining if
    # it has changed or not. So now it is a param and only applies on creation
    newparam(:password) do
      desc "Password. Only set on create."
    end
    
    newproperty(:superuser) do
      desc "Superuser. A boolean value that determines if the role is a super user.
Defaults to false when a role is created, but has no default value here.
If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:inherits) do
      desc "Inherits. A boolean value that determines if the role can inherit permissions
from roles it is a member of. Defaults to true in postgres, but has no default value here.
If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:createrole) do
      desc "Create role. A boolean value that determines if the role can create other roles.
Defaults to false in postgres, but has no default value here.
If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:createdb) do
      desc "Create database. A boolean value that determines if the role can create new databases.
Defaults to false, but has no default value here.
If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:login) do
      desc "Login. A boolean value that determines if the role can log in or not. This property
is the dividing line between users and groups, users can log in, groups can not. Defaults
to true, but has no default value here.
If unset, we don't care to simplify using the type."
      newvalues(:true, :false)
    end
    
    newproperty(:connlimit) do
      desc "Connection limit. -1 for none"
      # Add validation here, this should be a number
      defaultto '-1'
    end

    newproperty(:groups, :array_matching => :all) do
      desc "An array of roles that the role is a member of.
This is case sensitive and the back-end queries will automatically enclose anything containing uppercase letters
or spaces in quotes.
Be careful mixing use of this with members as they are evaluated seperately."
 
      def should=(value)
        super
        if value.is_a? Array
          @should.sort! # Sort these because order in no way matters.
        elsif value.is_a? String
          @should = [] << value
        else
          raise ArgumentError "Groups property must be an array or string."
        end
      end
      defaultto Array.new
    end

    newproperty(:members, :array_matching => :all) do
      desc "An array of roles that are a member of this role.
This is case sensitive and the back-end queries will automatically enclose anything containing uppercase letters
or spaces in quotes.
Be careful mixing use of this with groups as they are evaluated seperately."


      def should=(value)
        super
        if value.is_a? Array
          @should.sort! # Sort these because order in no way matters.
        elsif value.is_a? String
          @should = [] << value
        else
          raise ArgumentError "Members property must be an array or string."
        end
      end
             
      defaultto Array.new
    end
    
    # Autorequire roles
    autorequire(:pg_role) do
      roles = []
      roles << self[:groups] if self[:groups]
      roles << self[:members] if self[:members]
      roles
    end
    
    # Require the postgres service
    autorequire(:service) do
      [ "postgres", "postgresql" ]
    end
  end
end