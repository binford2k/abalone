# abalone
A simple Sinatra & hterm based web terminal. You can bind it to any command that behaves
like a shell and expose that to a browser.

#### Table of Contents

1. [Overview](#overview)
1. [Configuration](#configuration)
    1. [SSH](#configuring-ssh)
    1. [Custom Login Command](#configuring-a-custom-command)
1. [jQuery plugin](#jquery-plugin)
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
* `:welcome`
  * A message to display prior to starting a session. This is on the overlay with the
    *Start Session* button. Pass a string of text, or a filename. HTML will be interpreted.
  * Default value: unset
* `:logfile`
  * The path of a file to log to.
  * Default value: Log only to `STDERR`. If you pass `-l` at the command line
    with no filename, it will log to `/var/log/abalone`.
* `:timeout`
  * Maximum number of seconds a session can last. The shell will be killed at the
    end of that time. For example, set it to 300 for shells that last for up to
    five minutes.
  * Default value: unset.
* `:ttl`
  * The number of seconds a session should last after disconnecting. If you reconnect
    within this grace period, you'll be reconnected to your session without interruption.
    This cannot yet restore the secondary terminal buffer, so if you're running something
    like Vim, you may have to run `clear` or `reset` after exiting to get your console
    sane again.
  * Note that `:timeout` takes precedence, so if your session times out, even during
    the `:ttl` grace period, it will be killed. 
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

## jQuery Plugin

Abalone comes with a build in jQuery plugin that makes it very easy to use. You
can attach the launcher to any element. If it's a `block` element, then a launcher
button will be injected inside, and if it's `inline` then it will directly trigger
the terminal.

See a demo of the launcher in action after installation by starting the server and
browsing to [http://localhost:9000/demo.html](http://localhost:9000/demo.html).
Adjust the URL and port as needed.

The minimum external dependencies are jQuery and jQuery UI:

    <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css">
    <script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
    <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>

To load and initialize the launcher, you'll need to load the CSS and Javascript
from a running Abalone instance like below. Notice the full URL, including the
port number. Alternatively, you can pull those from the repository and host them
along with the rest of your HTML.

    <link rel="stylesheet" href="http://localhost:9000/css/launcher.css">
    <script src="http://localhost:9000/js/launcher.js"></script>

Then you'll simply declare one or more launchers on any element you choose. Note
that you must pass in the server parameter. This should be the location of your
Abalone server, including the port it's running on.

    <script>
      $(document).ready(function() {

        $('pre.popup').AbaloneLauncher({
           label: "Try out a popup!",
           title: "Isn't this neat?",
          server: "http://localhost:9000",
        });

        $('pre.inline').AbaloneLauncher({
             label: "Try it out inline!",
            target: "inline",
            server: "http://localhost:9000",
        });

        $('pre.targeted').AbaloneLauncher({
             label: "Try it out!",
            target: "#abalone-shell",
          location: "se",
            server: "http://localhost:9000",
        });

        $('a#launcher').AbaloneLauncher({
          server: "http://localhost:9000",
          params: { "type": "demo", "uuid": generateUUID() },
        });

      });
    </script>

### Configuration Options

| Option     | Valid values                                          | Default               |
|------------|-------------------------------------------------------|-----------------------|
| `location` | `ne`, `se`, `sw`, `nw`                                | `ne`                  |
| `label`    | *String*                                              | *Launch*              |
| `title`    | *String*                                              | *Abalone Web Shell*   |
| `target`   | `popup`, `inline`, `tab`, CSS selector of a container | `popup`               |
| `params`   | parameters to be passed to the server                 | `{}`                  |
| `server`   | URL to the Abalone server, including port             | `null` (**required**) |
| `height`   | *Integer*                                             | `480`                 |
| `width`    | *Integer*                                             | `640`                 |


## Limitations

This is super early in development and has not yet been battle tested.

## Disclaimer

I take no liability for the use of this tool.

Contact
-------

binford2k@gmail.com

