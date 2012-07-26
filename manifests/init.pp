import "classes/*.pp"
import "definitions/*.pp"

class postgres {
  pg_role { 'test':
    ensure => present,
    password => 'supersecret',
    login => true,
  } ->
  pg_database { 'test':
    ensure => present,
    owner => 'test',
  } ->
  pg_hba { 'test':
    file => '/data/pgsql/data/pg_hba.conf',
    role => 'test',
    type => 'host',
    database => 'test',
    address => '0.0.0.0/0',
    method => 'md5',
  } -> 
  pg_exec { 'test': query => "SELECT BLARGH from pg_catalog.pg_database", exec => 'INSERT INTO blah blah' }
}
