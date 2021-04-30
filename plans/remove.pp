# @summary Plan for removing CrowdStrike Falcon Sensor.
#
plan crowdstrike::remove (
  TargetSpec $targets,
) {

  $targets.apply_prep

  $results = apply($targets) {
    class { 'crowdstrike':
      ensure => absent,
    }
  }

  return $results
}
