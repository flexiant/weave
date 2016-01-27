Weave Cookbook
===============
Weave Cookbook is a library cookbook that provides resources to install and manage the Weave

Supported Platforms
-------------------
This cookbook is intended to be used with Linux using systemd. SysV, Init.d and Upstart are not supported.

Requirements
------------
- Chef 12.x.x
- Network access to Weave github repository

If you use the `docker_hook` action:
- Docker will be installed and configured from that action, make sure no existing docker installation is present
- Set docker_hook property to `true`

Dependencies
------------
- [compat_resource](https://supermarket.chef.io/cookbooks/compat_resource)
- [docker](https://supermarket.chef.io/cookbooks/docker)

Resources
---------
This cookbook contains only one resource
- `weave_service`

Actions
-------
- `:create` - Installs weave binary, creates the docker hook, and setup Weave service.
- `:install`- Downloads weave binary to the default location.
- `:docker_hook` - configures weave bridge and creates docker service configured to use it.
- `:setup` - download weave docker images and configures the weave systemd service
- `:start` - Start weave service (only it it exists already)
- `:stop` - Stops weave service (only it it exists already)
- `:restart` - Restarts the service

Properties
----------
- `ip`: ip CIDR assigned to the weave interface.
- `ip_alloc_range`: CIDR that defines the IP range to be assigned to containers in all nodes.
- `subnet`: CIDR that defines the IP range to be assigned to containers in this node.
- `password`: weave network password.
- `docker_hook`: if set to true, activates the docker_hook action.
- `is_master`: set to true if this is the first node in the weave network.
- `master`: set to an existing node to join its network. Won't be used if `is_master` is true.
- `version`: weave release version.
- `source`: URL where weave binary can be downloaded.


Usage
-----

You will usually use the `weave_service` resource in your cookbooks to create the weave service, including docker hooks, and then start it.

```
weave_service 'weave overlay docker' do
  ip '10.2.0.0/16'
  ip_alloc_range '10.2.0.0/16'
  is_master true
  docker_hook true
  password 'very.secret'
  version 'latest_release'
  action [ :create, :start ]
end
```
