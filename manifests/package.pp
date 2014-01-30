# = Class: sensu::package
#
# Installs the Sensu packages
#
class sensu::package {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  case $::operatingsystem {

    'Debian','Ubuntu': {
      class { 'sensu::repo::apt': }
    }

    'Fedora','RedHat','Centos': {
      class { 'sensu::repo::yum': }
    }

    default: { alert("${::operatingsystem} not supported yet") }

  }

  case $::kernel {
    'windows': {
      $msi_version = latest_sensu_msi_version()
      $msi_url = latest_sensu_msi_url()
      $msi_file = "sensu-${msi_version}.msi"
      # Install MSI.
      # download to C:\Windows\Downloaded Program Files
      File<| owner == 'sensu' |> {
        owner => 'Administrators',
        group => 'Administrators',
        mode => '0770',
      }
      exec { "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -executionpolicy remotesigned Invoke-WebRequest ${msi_url} -OutFile ${msi_file}":
        cwd => 'C:\Windows\Temp',
        creates => 'c:\opt\sensu',
      } ->
      file { 'C:\etc':
        ensure => directory,
      } ->
      file { 'C:\etc\sensu':
        ensure => directory,
        mode => '0775',
        owner => 'sensu',
        group => 'sensu',
      } ->
      package { 'Sensu':
        ensure  => installed,
        alias => 'sensu',
        source => "C:\\Windows\\Temp\\${msi_file}",
        provider => 'windows',
        install_options => '/quiet',
      } ->
      # Write out service definition xml.
      file { 'c:/opt/sensu/bin/sensu-client.xml':
        content => '
<!--   Windows service definition for Sensu -->
<service>
  <id>sensu-client</id>
  <name>Sensu Client</name>
  <description>This service runs a Sensu client</description>
  <executable>C:\opt\sensu\embedded\bin\ruby</executable>
  <arguments>C:\opt\sensu\embedded\bin\sensu-client -d C:\etc\sensu\conf.d -l C:\opt\sensu\sensu-client.log</arguments>
</service>
        ',
      } ->
      # Register service.
      exec { 'C:\Windows\System32\sc.exe create sensu-client start= delayed-auto binPath= c:\opt\sensu\bin\sensu-client.exe DisplayName= "Sensu Client"':
        path => $::path,
        cwd => 'c:/opt/sensu/bin',
        unless => 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy remotesigned Get-Service -Name sensu-client',
      }
    }
    default: {
      package { 'sensu':
        ensure  => $sensu::version,
      }

      file { '/etc/default/sensu':
        ensure  => file,
        content => template("${module_name}/sensu.erb"),
        owner   => '0',
        group   => '0',
        mode    => '0444',
        require => Package['sensu'],
      }
    }
  }

  file { [ "${sensu::config_dir}/conf.d", "${sensu::config_dir}/conf.d/handlers", "${sensu::config_dir}/conf.d/checks", "${sensu::config_dir}/conf.d/filters" ]:
    ensure  => directory,
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0775',
    purge   => $sensu::purge_config,
    recurse => true,
    force   => true,
    require => Package['sensu'],
  }

  file { ["${sensu::config_dir}/plugins", "${sensu::config_dir}/handlers"]:
    ensure  => directory,
    mode    => '0775',
    owner   => 'sensu',
    group   => 'sensu',
    require => Package['sensu'],
  }

  if $sensu::manage_user and $::kernel != 'windows' {
    user { 'sensu':
      ensure  => 'present',
      system  => true,
      home    => '/opt/sensu',
      shell   => '/bin/false',
      comment => 'Sensu Monitoring Framework',
    }
    group { 'sensu':
      ensure  => 'present',
      system  => true,
    }
  }

  file { "${sensu::config_dir}/config.json": ensure => absent }
}
