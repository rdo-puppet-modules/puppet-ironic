# == Class: ironic::db
#
#  Configure the Ironic database
#
# === Parameters
#
# [*database_connection*]
#   Url used to connect to database.
#   (Optional) Defaults to 'sqlite:////var/lib/ironic/ovs.sqlite'.
#
# [*database_idle_timeout*]
#   Timeout when db connections should be reaped.
#   (Optional) Defaults to 3600.
#
# [*database_max_retries*]
#   Maximum db connection retries during startup.
#   Setting -1 implies an infinite retry count.
#   (Optional) Defaults to 10.
#
# [*database_retry_interval*]
#   Interval between retries of opening a sql connection.
#   (Optional) Defaults to 10.
#
# [*database_min_pool_size*]
#   Minimum number of SQL connections to keep open in a pool.
#   (Optional) Defaults to 1.
#
# [*database_max_pool_size*]
#   Maximum number of SQL connections to keep open in a pool.
#   (Optional) Defaults to 10.
#
# [*database_max_overflow*]
#   If set, use this value for max_overflow with sqlalchemy.
#   (Optional) Defaults to 20.
#
class ironic::db (
  $database_connection     = 'sqlite:////var/lib/ironic/ovs.sqlite',
  $database_idle_timeout   = 3600,
  $database_max_retries    = 10,
  $database_retry_interval = 10,
  $database_min_pool_size  = 1,
  $database_max_pool_size  = 10,
  $database_max_overflow   = 20,
) {

  # NOTE(spredzy): In order to keep backward compatibility we rely on the pick function
  # to use ironic::<myparam> if ironic::db::<myparam> isn't specified.
  $database_connection_real = pick($::ironic::database_connection, $database_connection)
  $database_idle_timeout_real = pick($::ironic::database_idle_timeout, $database_idle_timeout)
  $database_max_retries_real = pick($::ironic::database_max_retries, $database_max_retries)
  $database_retry_interval_real = pick($::ironic::database_retry_interval, $database_retry_interval)
  $database_min_pool_size_real = pick($::ironic::database_min_pool_size, $database_min_pool_size)
  $database_max_pool_size_real = pick($::ironic::database_max_pool_size, $database_max_pool_size)
  $database_max_overflow_real = pick($::ironic::database_max_overflow, $database_max_overflow)

  validate_re($database_connection_real,
    '(sqlite|mysql|postgresql):\/\/(\S+:\S+@\S+\/\S+)?')

  if $database_connection_real {
    case $database_connection_real {
      /^mysql:\/\//: {
        $backend_package = false
        require 'mysql::bindings'
        require 'mysql::bindings::python'
      }
      /^postgresql:\/\//: {
        $backend_package = $::ironic::params::psycopg_package_name
      }
      /^sqlite:\/\//: {
        $backend_package = $::ironic::params::sqlite_package_name
      }
      default: {
        fail('Unsupported backend configured')
      }
    }

    if $backend_package and !defined(Package[$backend_package]) {
      package {'ironic-backend-package':
        ensure => present,
        name   => $backend_package,
        tag    => 'openstack',
      }
    }

    ironic_config {
      'database/connection':     value => $database_connection_real, secret => true;
      'database/idle_timeout':   value => $database_idle_timeout_real;
      'database/max_retries':    value => $database_max_retries_real;
      'database/retry_interval': value => $database_retry_interval_real;
      'database/min_pool_size':  value => $database_min_pool_size_real;
      'database/max_pool_size':  value => $database_max_pool_size_real;
      'database/max_overflow':   value => $database_max_overflow_real;
    }
  }

}
