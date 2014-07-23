# == Class etcd::install
#
class etcd::install {
  # Create group and user if required
  if $etcd::manage_user {
    group { $etcd::group: ensure => 'present' }

    user { $etcd::user:
      ensure  => 'present',
      gid     => $etcd::group,
      require => Group[$etcd::group],
      before  => Package['etcd']
    }
  }

  # Create etcd data dir if required
  if $etcd::manage_data_dir {
    file { $etcd::data_dir:
      ensure => 'directory',
      owner  => $etcd::user,
      group  => $etcd::group,
      mode   => '0750',
      before => Package['etcd']
    }
  }

  # Create etcd log dir if required
  if $etcd::manage_log_dir {
    file { $etcd::log_dir:
      ensure => 'directory',
      owner  => $etcd::user,
      group  => $etcd::group,
      mode   => '0750',
      before => Package['etcd']
    }
  }

  # Setup resource ordering if appropriate
  if ($etcd::manage_user and $etcd::manage_data_dir) {
    User[$etcd::user] -> File[$etcd::data_dir]
  }
  if ($etcd::manage_user and $etcd::manage_log_dir) {
    User[$etcd::user] -> File[$etcd::log_dir]
  }

  if $etcd::install_from_source {
    exec { 'download_go':
      command => 'curl -s https://storage.googleapis.com/golang/go1.3.src.tar.gz | tar -v -C /usr/local -xz',
      path    => '/bin:/usr/bin',
      unless  => ['test -e /usr/local/go'],
    } ->

    exec { 'build_go':
      command => '/usr/local/go/src/make.bash --no-clean 2>&1',
      path    => '/bin:/usr/bin:/usr/local/go/bin',
      cwd     => '/usr/local/go/src',
      unless  => ['test -e /usr/local/go/bin'],
    } ->

    exec { 'download_etcd':
      command => 'wget https://github.com/coreos/etcd/archive/v0.4.5.tar.gz && tar -xvf v0.4.5.tar.gz',
      path    => '/bin:/usr/bin:/usr/local/bin:/usr/local/go/bin',
      cwd     => '/opt',
      unless  => ['test -e /opt/etcd-0.4.5'],
    } ->

    exec { 'build_etcd':
      command => '/bin/sh /opt/etcd-0.4.5/build',
      cwd     => '/opt/etcd-0.4.5',
      path    => '/bin:/usr/bin:/usr/local/bin:/usr/local/go/bin',
      unless  => ['test -e /opt/etcd-0.4.5/bin'],
    } ->

    exec { 'install_etcd':
      command => 'cp /opt/etcd-0.4.5/bin/etcd ' + $etcd::binary_location,
      cwd     => '/opt/etcd-0.4.5',
      path    => '/bin',
      unless  => ['test -e /opt/etcd-0.4.5/bin'],
    }
  }
  else {

    # Install the required package
    package { 'etcd':
      ensure => $etcd::package_ensure,
      name   => $etcd::package_name,
    }

  }
}
