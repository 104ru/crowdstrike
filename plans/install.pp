# @summary Plan for installing CrowdStrike Falcon Sensor.
#
# @param [TargetSpec] targets
#   Target nodes to install Falcon Sensor on.
#
# @param [String] cid
#   Customer IDentifier. Necessary to register the agent with the service. Mandatory.
#
# @param [Optional[String]] source
#   Source for falcon-sensor package. Use system repos if not specified.
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
plan crowdstrike::install (
  TargetSpec $targets,
  String $cid,
  Optional[String] $source = undef,
  Optional[Array[String]] $tags = undef,
  Optional[String] $proxy_host = undef,
  Optional[Stdlib::Port] $proxy_port = undef,
) {

  $targets.apply_prep

  # Upload package if source specified.
  if $source {
    $local_package = "/tmp/${source.basename}"
    upload_file($source, $local_package, $targets)
  } else {
    $local_package = undef
  }

  # Install Falcon Sensor.
  $results = apply($targets) {
    class { '::crowdstrike':
      ensure     => 'present',
      source     => $local_package,
      cid        => $cid,
      tags       => $tags,
      proxy_host => $proxy_host,
      proxy_port => $proxy_port,
    }
  }

  # Cleanup.
  if $source {
    run_command("rm -f ${local_package}", $targets)
  }

  return $results
}
