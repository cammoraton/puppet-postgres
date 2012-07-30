module Puppet
  newtype(:pg_database) do
    @doc = "Type for manipulating postgres databases."

    ensurable

    newparam(:name) do
      desc "Name identifier of this database. This value needs to be unique."
      # Need to do some validation
      isnamevar
    end
    
    newproperty(:owner) do
      desc "Name of the owner of the database"
       # Need to do some validation
    end
    
    # The following three are properties, but behave as parameters.
    # I overrode the default behavior/difference by having the getters in the provider return
    # the @resource value.  I'm still waffling back and forth on having these be changeable
    # post-initialization.  If I settle on not allowing that, then I'll flip them to params.
    newproperty(:encoding) do
      desc "Encoding.  The character set text/data is stored in.  Defaults to UTF8.
Note that changing this is very dangerous, so it will only be set when a database is created.

For more information see:
- http://www.postgresql.org/docs/8.4/static/multibyte.html
or
- http://www.postgresql.org/docs/9.0/static/multibyte.html"
      newvalues('BIG5', 'EUC_CN', 'EUC_JP', 'EUC_KR', 'EUC_TW', 'GB18030', 'GBK', 'ISO_8859_5', 
                'ISO_8859_6', 'ISO_8859_7', 'ISO_8859_8', 'JOHAB', 'KOI8', 'LATIN1', 'LATIN2',
                'LATIN3', 'LATIN4', 'LATIN5', 'LATIN6', 'LATIN7', 'LATIN8', 'LATIN9', 'LATIN10',
                'MULE_INTERNAL', 'SJIS', 'SQL_ASCII', 'UHC', 'UTF8', 'WIN866', 'WIN874', 'WIN1250',
                'WIN1251', 'WIN1252', 'WIN1256', 'WIN1258')
      defaultto 'UTF8'
    end
    
    newproperty(:collate) do
      desc "This has no default(trust in postgres).  It's the locale + encoding.
Note that changing this is very dangerous, so it will only be set when a database is created.
      
For more information see:
- http://www.postgresql.org/docs/8.4/static/multibyte.html
or
- http://www.postgresql.org/docs/9.0/static/multibyte.html"
    end
    
    newproperty(:ctype) do
      desc "This has no default(trust in postgres).  It's the locale + encoding.
Note that changing this is very dangerous, so it will only be set when a database is created.
      
For more information see:
- http://www.postgresql.org/docs/8.4/static/multibyte.html
or
- http://www.postgresql.org/docs/9.0/static/multibyte.html"
    end
    
    # Require the role.
    autorequire(:pg_role) do
      @parameters[:owner]
    end
    
  end
end
