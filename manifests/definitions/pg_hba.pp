# Exploits the pg_hba augeas lens
define pg_hba ( $ensure = 'present', 
                $type,
                $database,
                $role,
                $address = false,
                $method,
                $option = false,
                $file ) {
   if ! $file {
     fail("File parameter is mandatory.")
   }
   if ! $type {
     fail("Type parameter is mandatory.")
   }
   # Possible require the pg_database with this name
   if ! $database {
     fail("Database parameter is mandatory.")
   }
   # Possibly require the pg_role with this name
   if ! $role {
     fail("Role parameter is mandatory.")
   }
   # Add validation at some point
   # Valid methods are "trust", "reject", "md5", "password", "gss", "sspi", "krb5",
   # "ident", "pam", "ldap" or "cert"
   if ! $method {
     fail("Method parameter is mandatory.")
   }
   
   # There are two general classes of pg_hba entries
   # Local for socket connections
   # And then everything else   
   case $type {
     'local': {
       #We do 2 different augeas commands here and then
       #execute one or the other based on 2 match onlyif rules
       $changed = [ # Order Matters
         "set /files${file}/01/type local",
         "set /files${file}/01/database ${database}",
         "set /files${file}/01/user ${role}",
         "set /files${file}/01/method ${method}",
       ]
       $match = "/files${file}/*[ type = 'local'][database = '${database}'][user = '${role}'][method = '${method}']"
     }
     'host', 'hostssl', 'hostnossl': {
       if ! $address {
         fail("Address parameter is required for host, hostssl and hostnossl types")
       }
       $changed = [ # Order Matters
         "set /files${file}/01/type ${type}",
         "set /files${file}/01/database ${database}",
         "set /files${file}/01/user ${role}",
         "set /files${file}/01/address ${address}",
         "set /files${file}/01/method ${method}",
       ]
       $match = "/files${file}/*[type = '${type}'][database = '${database}'][user = '${role}'][address = '${address}'][method = '${method}']"
     }
     default: {
       fail ("Unrecognized type.  Valid types are 'local', 'host', 'hostssl', and 'hostnossl'")
     }
   }
   
   case $ensure {
     'present': {
        augeas { "set pg_hba ${name}":
          lens => "Pg_Hba.lns",
          incl => $file,
          changes => $changed,
          onlyif => "match ${match} size == 0",
        }
        # Need to add in method options
        # Need to add notify in to reload postgres
     }
     'absent': {
       augeas { "remove pg_hba ${name}":
         lens => "Pg_Hba.lns",
         incl => $file,
         changes => "rm ${match}",
         onlyif  => "match ${match} size == 1",
       }
       # Need to add notify in to reload postgres
     }
     default: {
       fail("Ensure must be set to present or absent.")
     }                         
  }
}