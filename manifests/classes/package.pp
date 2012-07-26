class postgres {
  class package {
    case $operatingsystem {
      'redhat', 'centos': {
        $postgres_data_dir = '/var/lib/pgsql'
        $postgres_etc_dir = '/etc/postgres'
        package {'postgresql-server': ensure => present, alias => 'postgres'}
      }
      default: {
        fail ("Unsupported operating system")
      }
    }
    class contrib {
      case $operatingsystem {
        'redhat', 'centos': {
           $postgres_contrib_dir = '/usr/share/pgsql/contrib'
           package {'postgresql-contrib': ensure => present, alias => 'postgres-contrib' }
        }
        default: {
          fail ("Unsupported operating system")
        }
      }
    }
  }
}  
  
    