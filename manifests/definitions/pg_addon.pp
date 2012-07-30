# Wrapper to pg_exec specifically for installation of addons
# kind of RHEL specific, but really apart from the contrib path,
# debian derivatives aren't THAT different. 

define pg_addon ($function     = $name,
                 $refreshonly  = false,
                 $contrib_path = '/usr/share/pgsql/contrib', # Yea, we default to rhel
                 $file         = "${name}.sql",
                 $uninstall    = "uninstall_${file}",
                 $database     = 'postgres',
                 $user         = 'postgres',
                 $ensure       = 'present' ) {

   case $ensure {
     'present': {
     # Queries the specified database for the function name(defaults to addon name)
	   # and then executes the sql install script if it the check returns 0 rows.
	   pg_exec { "install addon ${name}":
	     rows        => '0', 
	     file        => "${contrib_path}/${file}",
	     role        => $user,
	     database    => $database,
	     refreshonly => $refreshonly,
	     query       => "SELECT proname FROM pg_catalog.pg_namespace n
	                     JOIN pg_catalog.pg_proc p ON pronamespace = n.oid
	                     WHERE nspname = 'public' AND proname = '${function}'",
	   }
	}
	'absent': {
	  # Queries the specified database for the function name(defaults to addon name)
	  # and then executes the sql uninstall script if it the check returns more than 0 rows.
	  pg_exec { "uninstall addon ${name}":
	     rows        => 'greater than 0', 
	     file        => "${contrib_path}/${uninstall}",
	     role        => $user,
	     database    => $database,
	     refreshonly => $refreshonly,
	     query       => "SELECT proname FROM pg_catalog.pg_namespace n
	                     JOIN pg_catalog.pg_proc p ON pronamespace = n.oid
	                     WHERE nspname = 'public' AND proname = '${function}'",
	   }
	}
	default: {
	  fail("Unrecognized parameter for ensure")
	}
  }
}
