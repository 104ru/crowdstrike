# Changelog

All notable changes to this project will be documented in this file.

## Release 1.4.5

* Improve Deferred/Sensitive handling of CID and Install Token. Merge
  [#15](https://github.com/104ru/crowdstrike/pull/15). Thanks @tedgarb.

## Release 1.4.4

* Update fact to accomodate the changes in falconctl output in v6.51. Merge
  [#17](https://github.com/104ru/crowdstrike/pull/17). Thanks @tedgarb.

## Release 1.4.3

* Support deferred data type for CID and provisioning token. Merge
  [#14](https://github.com/104ru/crowdstrike/pull/14). Thanks @tedgarb.
* Drop support for RHEL 6 and SLES 12.

## Release 1.4.2

* Force falconctl to apply provided module parameters during the registration
  to prvent some edge cases when the module applied over the manual
  installation. Resolves [#12](https://github.com/104ru/crowdstrike/issues/12).
  Thanks, @RamblingCookieMonster for pointing it out.
* Expand unit test to cover more cases.
* Allow stdlib 8.x.

## Release 1.4.1

* Merged [#11](https://github.com/104ru/crowdstrike/pull/11) adding SLES
  support. Thanks, @thirumoorthir.

## Release 1.4.0

* Allow to change proxy settings when CID is set, but agent has not been
  registered yet. Closes [#8](https://github.com/104ru/crowdstrike/issues/8).
  Add a boolean key "cid" to the fact showing if CID has been set.
  Thanks @davealden.
* Merge [#7](https://github.com/104ru/crowdstrike/pull/7) adding capability to
  custiomize falcon-sensor package source and provider. Thanks @fe80.
* Add some more resilience to falconctl output format changes to the
  falcon_sensor fact.
* Fix logic in falcon_sensor fact, which was causing its failure if it becomes
  unable to parse falconctl output.
* Now falconctl fact returns distinct values in case of its failure to parse
  falconctl output or falconctl returning an error.
* Module is now capable of detecting falcon_sensor fact failure and gracefully
  handle the situation.

## Release 1.3.0

* Add `provisioning_token` parameter for a provisioning token.
  Closes [#6](https://github.com/104ru/crowdstrike/issues/6). Thanks @mnrazak.

## Release 1.2.4

* Update fact to parse changed output format of falconctl

## Release 1.2.3

* Handle manually installed falcon-sensor package. Closes
  [#3](https://github.com/104ru/crowdstrike/issues/3). Thanks @jstraw.

## Release 1.2.2

* Merge a [bug fix](https://github.com/104ru/crowdstrike/pull/1) for proxy
  port type mismatch at comparison. Thanks @richardnixonshead. 

## Release 1.2.1

* Configure Travis CI build tests.

## Release 1.2.0

* Use PDK 2.0, add metadata and unit test.
* Fix undefined variable if no tags given at registration time. 

## Release 1.1.0

Do not show undefined keys in facter.

## Release 1.0.0

Initial release
