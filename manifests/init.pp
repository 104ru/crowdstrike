# @summary
#   Simple module installing CrowdStrike's Falcon Agent
#
# The module is designed to install, manage and remove CrowdStrike's Falcon Agent antivirus.
# Tags and proxy settings can be changed any time using module parameters.
#
# @param [Enum['present','absent','latest']] ensure
#   If `present` or `latest` installs the agent, keeping it up-to-date with the latter value.
#   When set to `absent` uninstalls the agent's package.
#
# @param [Optional[String]] source
#   Source for Falcon Sensor package. If not defined, package is downloaded from a repo
#   defined on the system.
#
# @param [Optional[String]] cid
#   Customer IDentifier. Necessary to register the agent with the service. Mandatory.
#
# @param [Optional[Array[String]]] tags
#   Array of string tags used to group agents in the CrowdStrike console.
#
# @param [Optional[String]] proxy_host
#   Proxy server host name for proxied connections. Mandatory if `proxy_port` is specified.
#
# @param [Optional[Stdlib::Port]] proxy_port
#   Proxy server port for proxied connections. Mandatory if `proxy_host` is specified.
#
# @example Install Falcon Agent and use proxy for connections
#
#   class { '::crowdstrike':
#     ensure     => present,
#     cid        => 'AAAAAAAAAAAAAAA-BB' ,
#     tags       => [ 'my_company', 'my_organization' ],
#     proxy_host => 'proxy.mycompany.com',
#     proxy_port => 3128
#   }
#
# @see
#   https://www.crowdstrike.com/endpoint-security-products/falcon-endpoint-protection-enterprise/
#
#
class crowdstrike (
  Enum['present','absent','latest'] $ensure = 'present',
  Optional[String] $source = undef,
  Optional[String] $cid = undef,
  Optional[Array[String]] $tags = undef,
  Optional[String] $proxy_host = undef,
  Optional[Stdlib::Port] $proxy_port = undef,
){
  if $ensure == 'absent' {
  
    $pkg_ensure = $facts['os']['family'] ? {
      'Debian' => 'purged',
      default  => 'absent'
    }
    package { 'falcon-sensor': ensure => $pkg_ensure }
    
  } else {

    # install package
    if $source {
      $pkg_provider = $facts['os']['family'] ? {
        'Debian' => 'dpkg',
        default  => 'rpm',
      }
      package { 'falcon-sensor':
        ensure   => present,
        provider => $pkg_provider,
        source   => $source,
      }
    } else {
      package { 'falcon-sensor': ensure => $ensure }
    }
    
    # tags that have to be applied
    if $tags {
      $tags_str = join($tags, ',')
      $cmd_tags = " --tags=${tags_str}"
    } else {
      $cmd_tags = ''
    }

    # see if proxy needs to be disabled.
    $disable_proxy = (($proxy_host == undef) or ($proxy_port == undef))

    if $disable_proxy {
      # crowdstrike has a separate switch for disabling proxy, not
      # just abscense of host name and/or port.
      $cmd_proxy = ' --apd=TRUE'
    } else {
      $cmd_proxy = " --apd=FALSE --aph=${proxy_host} --app=${proxy_port}"
    }

    if 'falcon_sensor' in $facts {
      # crowdstrike is installed
      # get currently used tags
      $current_tags = $facts.get('falcon_sensor.tags', undef)
      if $current_tags and (sort($tags) != sort($current_tags)) {
        $update_tags = $cmd_tags
      } else {
        $update_tags = ''
      }

      # get current proxy settings
      $current_proxy_disable = $facts.get('falcon_sensor.proxy_disable', true)
      $current_proxy_host = $facts.get('falcon_sensor.proxy_host', undef)
      $current_proxy_port = $facts.get('falcon_sensor.proxy_port', undef)

      if $disable_proxy {
        if ($current_proxy_disable == false) {
          # if proxy is enabled, but has to be disabled
          $update_proxy = $cmd_proxy
        } else {
          # if proxy is disabled and has to stay disabled
          $update_proxy = ''
        }
      } else {
        if (
          ($current_proxy_host != $proxy_host) or
          (String($current_proxy_port) != String($proxy_port)) or
          ($current_proxy_disable == true)
        ) {
          # if proxy is disabled, but has to be enabled or host/port have changed
          $update_proxy = $cmd_proxy
        } else {
          # if proxy is enabled and has to stay enabled and host/port stayed the same
          $update_proxy = ''
        }
      }

      if ($update_tags != '') or ($update_proxy != '') {
        exec { 'update-falcon-settings':
          path    => '/usr/bin:/usr/sbin:/opt/CrowdStrike',
          command => "falconctl -sf${update_proxy}${update_tags}",
          require => Package['falcon-sensor'],
          notify  => Service['falcon-sensor'],
        }
      }
    } else {
      # register crowdstrike first
      if !$cid {
        fail('CID parameter must be specified to register the agent!')
      }

      $cmd_cid = " --cid=${cid}"

      exec { 'register-crowdstrike':
        path    => '/usr/bin:/usr/sbin:/opt/CrowdStrike',
        command => "falconctl -s${cmd_cid}${cmd_proxy}${cmd_tags}",
        require => Package['falcon-sensor'],
        notify  => Service['falcon-sensor'],
      }
    }

    service { 'falcon-sensor':
      ensure  => running,
      enable  => true,
      require => Package['falcon-sensor']
    }
  }
}
