# abalone
A simple Sinatra & hterm based web terminal.

#### Table of Contents

1. [Overview](#overview)
1. [Configuration](#configuration)
    1. [SSH](#configuring-ssh)
    1. [Custom Login Command](#configuring-a-custom-command)
1. [Limitations](#limitations)

## Overview

Simply exposes a login shell to a web browser. This is currently
nowhere near to production quality, so don't actually use it.

It supports three methods for providing a shell:

1. Simply running the `login` binary and logging in as a system user. (default)
1. Using SSH to connect to localhost or a remote machine. This can be configured
   with credentials to automatically connect, or it can request a username and
   password from the end user.
1. Running custom command, which can be configured with arbitrary parameters.

## Configuration

Abalone defaults to loading configuration from `/etc/abalone/config.yaml`. You
can pass the path to another config file at the command line. In that file, you
can set several options:

* `:autoconnect`
  * Set this to true if you'd like the session to start on page load and false
    if you'd like the user to click a *Start Session* button instead. Defaults
    to `true`.
* `:port`
  * Which port to run the server on.
  * Default value: `9000`
* `:bind`
  * The hostname or IP address of the interface to listen on.
  * Default value: `0.0.0.0` (listen to all interfaces.)
* `:bannerfile`
  * File to display before login. This does not interpret special characters the way `getty` does.
  * `true`, `false`, or filename to display.
  * Default value: `false`, or `/etc/issue.net` if set to `true`.
* `:logfile`
  * The path of a file to log to.
  * Default value: Log only to `STDERR`. If you pass `-l` at the command line
    with no filename, it will log to `/var/log/abalone`.
* `:timeout`
  * Maximum number of seconds a session can last. The shell will be killed at the
    end of that time. For example, set it to 300 for shells that last for up to
    five minutes.
  * Default value: unset.
* One of [`:command`](#configuring-a-custom-command) or [`:ssh`](#configuring-ssh), exclusive.
  * The login method to use. Abalone can use `login`, SSH, or a custom command
    to start a shell. See configuration instructions below.
  * Default value: uses the `login` binary, with no configuration possible.

### Configuring SSH

The following parameters may be used to configure SSH login. The `:host` setting
is required. `:user` and `:cert` are optional. If `:user` is not set, then the
user will be prompted for a login name, and if `:cert` is not set then
the user will be prompted to log in with a password. If the SSH server is running
on a non-standard port, you may specify that with the `:port` setting.

``` Yaml
---
:ssh:
  :host: shellserver.example.com
  :user: centos
  :cert: /etc/abalone/centos.pem
```

### Configuring a custom command

A custom command can be configured in several ways. If you just want to run a
command without providing any options, the config file would look like:

``` Yaml
---
:command: /usr/local/bin/run-container
```

#### Simple options

You can also allow the user to pass in a arbitrary options. These must be
whitelisted. You can simply list allowed options in an Array:

``` Yaml
---
:command: /usr/local/bin/run-container
:params: [ 'username', 'image' ]
```

The options will be passed to the command in this way, ignoring the option
that was not whitelisted:

* http://localhost:9000/?username=bob&image=testing&invalid=value
* `/usr/local/bin/run-container --username bob --image testing`

#### Customized options

Finally, you can fully customize the options which may be passed in, including
remapping them to command line arguments and filtering accepted values. In this
case, `:params` must be a Hash.

``` Yaml
---
:command: /usr/local/bin/run-container
:params:
  username:
  type:
    :values: ['demo', 'testing']
  image:
    :map: '--create-image'
    :values: [ 'ubuntu', 'rhel', /centos[5,6,7]/ ]
```

Notice that `username` has nothing on the right side. It will be treated exactly
the same as `username` in the *Simple options* array above.

The `image` parameter is more complex though. It has two keys specified. Both are
optional. If `:map` is set, then its value will be used when running the command.
The `:values` key can be used to specify a list of valid values. Note that these
can be specified as Strings or regular expressions. 

The options in this case will be passed to the command like:

* An option is mapped to a different command line argument:
  * http://localhost:9000/?username=bob&image=centos6
  * `/usr/local/bin/run-container --username bob --create-image centos6`
* An option without a `:map` is passed directly through to the command:
  * http://localhost:9000/?username=bob&type=demo
  * `/usr/local/bin/run-container --username bob --type demo`
* Image name that doesn't pass validation is ignored:
  * http://localhost:9000/?username=bob&image=testing
  * `/usr/local/bin/run-container --username bob`
* Invalid options and values are ignored:
  * http://localhost:9000/?username=bob&image=testing&invalid=value
  * `/usr/local/bin/run-container --username bob`

## Limitations

This is super early in development and has not yet been battle tested.

## Disclaimer

I take no liability for the use of this tool.

Contact
-------

binford2k@gmail.com

