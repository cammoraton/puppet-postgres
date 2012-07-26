class postgres {
  class service {
    require postgres::package
    case $operatingsystem {
      'redhat', 'centos': {
        service { 'postgresql': ensure => running, enable => true, alias => postgres }
       }
      default: {
       fail ("Unsupported operating system")
      }
    }
  } 
}