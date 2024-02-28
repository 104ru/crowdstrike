[![Build Status](https://github.com/104ru/crowdstrike/workflows/CI/badge.svg)](https://github.com/104ru/crowdstrike/actions?query=workflow%3ACI)
[![Puppet Forge](https://img.shields.io/puppetforge/v/ruthenium/crowdstrike.svg)](https://forge.puppet.com/modules/ruthenium/crowdstrike)
[![Puppet Forge -- Downloads](https://shields.io/puppetforge/dt/ruthenium/crowdstrike)](https://forge.puppet.com/modules/ruthenium/crowdstrike)

# crowdstrike

The module is designed to deploy and manage CrowdStrike's Falcon Sensor
antivirus agent.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with crowdstrike](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with crowdstrike](#beginning-with-crowdstrike)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

The modules installs and manages or removes the Falcon Sensor anti-virus
agent by CrowdStrike. Proxy settings and tags can be confiugred additionaly. 

## Setup

### Setup requirements

The module installs a package `falcon-sensor`, which it assumes to be
available in a repo configured on the system. The vendor does not maintain
a Linux repository.

Alternatively you can customize package source and provider to have an ability
to install from a different source.

### Beginning with crowdstrike

The most basic usage of the module:

```puppet
class { 'crowdstrike': cid => 'AAAAAAAAAAAAA-BB' }
```

Parameter `cid` is mandatory.

## Usage

In most cases just specifying `cid` (customer id) is sufficient, but adding
tags is desirable for easy grouping and searching of the hosts in the
CrowdStrike console:

```puppet
class { 'crowdstrike':
  cid  => 'AAAAAAAAAAAA-BB',
  tags => [ 'My Organization', 'My Department' ]
}
```

If the computer does not have direct access to the CrowdStrike cloud service,
connection can be routed through a proxy server:

```puppet
class { 'crowdstrike':
  cid        => 'AAAAAAAAAAAA-BB',
  proxy_host => 'proxy-server.my-organization.com',
  proxy_port => 3128
}
```

Both `proxy_host` and `proxy_port` are mandatory if either specified.

If provisioning token is reqired during the installation, use the `provisioning_token`
parameter:

```puppet
class { 'crowdstrike':
  cid                => 'AAAAAAAAAAAA-BB',
  provisioning_token => 'XXXXXXXXXXXXXX'
}
```

## Limitations

If proxy has been used and later disabled, the host and port configuration is
not removed entirely, only disabled. This does not affect the functionality in
any way.

CrowdStrike sensor software is capable of auto-updating its binaries if
configured to do so in the console. It happened in the past when update changes
the format of the falconctl output, which may break the fact in this module. If
that happens, the module detects this situation, displays the relevant error
message and fails the puppet run. If you see this happening, it is time to
update the version of the module you have.

