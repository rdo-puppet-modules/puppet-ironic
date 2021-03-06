#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# Configure the conductor service in Ironic
#
# === Parameters
#
# [*package_ensure*]
#   (optional) Control the ensure parameter for the package ressource.
#   Defaults to 'present'.
#
# [*enabled*]
#   (optional) Define if the service must be enabled or not.
#   Defaults to true.
#
# [*max_time_interval*]
#   (optional) Maximum time, in seconds, since the last check-in of a conductor.
#   Should be an interger value
#   Defaults to '120'.
#
# [*force_power_state_during_sync*]
#   (optional) Should the hardware power state be set to the state recorded in
#   the database (True) or should the database be updated based on the hardware
#   state (False).
#   Defaults to true.
#
class ironic::conductor (
  $package_ensure                = 'present',
  $enabled                       = true,
  $max_time_interval             = '120',
  $force_power_state_during_sync = true,
) {

  include ::ironic::params

  Ironic_config<||> ~> Service['ironic-conductor']

  # Configure ironic.conf
  ironic_config {
    'conductor/max_time_interval': value => $max_time_interval;
    'conductor/force_power_state_during_sync': value => $force_power_state_during_sync;
  }

  # Install package
  if $::ironic::params::conductor_package {
    Package['ironic-conductor'] -> Service['ironic-conductor']
    package { 'ironic-conductor':
      ensure => $package_ensure,
      name   => $::ironic::params::conductor_package,
      tag    => ['openstack', 'ironic-package'],
    }
  }

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  # Manage service
  service { 'ironic-conductor':
    ensure    => $ensure,
    name      => $::ironic::params::conductor_service,
    enable    => $enabled,
    hasstatus => true,
    tag       => 'ironic-service',
  }

}
