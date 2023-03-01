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
# @param [Optional[Variant[String, Deferred]]] cid
#   Customer IDentifier. Necessary to register the agent with the service. Mandatory.
#
# @param [Optional[Variant[String, Deferred]]] provisioning_token
#   Provisioning token for the crowdstrike agent installation.
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
# @param [Optional[String]] package_source
#   Define a package source for installation
#
# @param [Optional[String]] package_provider
#   Define a package provider for installation
#
# @example Install Falcon Agent and use proxy for connections
#
#   class { '::crowdstrike':
#     ensure             => present,
#     cid                => 'AAAAAAAAAAAAAAA-BB',
#     provisioning_token => 'XXXXXXXXXXXXXXXXXX',
#     tags               => [ 'my_company', 'my_organization' ],
#     proxy_host         => 'proxy.mycompany.com',
#     proxy_port         => 3128
#   }
#
# @see
#   https://www.crowdstrike.com/endpoint-security-products/falcon-endpoint-protection-enterprise/
#
#
class crowdstrike (
  Enum['present','absent','latest'] $ensure                    = 'present',
  Optional[Variant[String, Deferred]] $cid                     = undef,
  Optional[Variant[String, Deferred]] $provisioning_token      = undef,
  Optional[Array[String]] $tags                                = undef,
  Optional[String] $proxy_host                                 = undef,
  Optional[Stdlib::Port] $proxy_port                           = undef,
  Optional[String] $package_source                             = undef,
  Optional[String] $package_provider                           = undef,
) {
  if $ensure == 'absent' {
    $pkg_ensure = $facts['os']['family'] ? {
      'Debian' => 'purged',
      default  => 'absent'
    }
  } else {
    $pkg_ensure = $ensure
  }

  package { 'falcon-sensor':
    ensure   => $pkg_ensure,
    source   => $package_source,
    provider => $package_provider,
  }

  if ($ensure != 'absent') {
    # confirm that the falcon_sensor fact is working, otherwise fail hard
    if 'falcon_sensor' in $facts {
      case $facts['falcon_sensor'] {
        'parsing_error': { fail('CrowdStrike module unalbe to parse falconctl output.') }
        'falconctl_error': { fail('CrowdStrike module encoutered and error while executing falconctl.') }
        default: {}
      }
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

    if ('falcon_sensor' in $facts) and $facts['falcon_sensor']['cid'] {
      # crowdstrike is installed and configured.
      # get currently used tags
      $current_tags = $facts.get('falcon_sensor.tags', [])
      if $tags and (sort($tags) != sort($current_tags)) {
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

      if $cid.is_a(Deferred) {
        $cmd_cid = Deferred('inline_epp', [' --cid="<%= $cid %>"', { 'cid' => $cid }])
      } else {
        $cmd_cid = " --cid=${cid}"
      }

      if $provisioning_token {
        if $provisioning_token.is_a(Deferred) {
          $cmd_token = Deferred(
            'inline_epp', [' --provisioning-token="<%= $provisioning-token %>"', { 'provisioning_token' => $provisioning_token }]
          )
        } else {
          $cmd_token = " --provisioning-token=${provisioning_token}"
        }
      } else {
        $cmd_token = ''
      }

      if $cmd_cid.is_a(Deferred) or $cmd_token.is_a(Deferred) {
        $_reg_command = Sensitive(Deferred('inline_epp', [
              'falconctl -sf<%= $cmd_cid %><%= $cmd_token %><%= $cmd_proxy %><%= $cmd_tags %>',
              { 'cmd_cid' => $cmd_cid, 'cmd_token' => $cmd_token, 'cmd_proxy' => $cmd_proxy, 'cmd_tags' => $cmd_tags },
        ]))
      } else {
        $_reg_command = Sensitive("falconctl -sf${cmd_cid}${cmd_token}${cmd_proxy}${cmd_tags}")
      }
      exec { 'register-crowdstrike':
        path    => '/usr/bin:/usr/sbin:/opt/CrowdStrike',
        command => $_reg_command,
        require => Package['falcon-sensor'],
        notify  => Service['falcon-sensor'],
      }
    }

    service { 'falcon-sensor':
      ensure  => running,
      enable  => true,
      require => Package['falcon-sensor'],
    }
  }
}
