# v0.4.2

* Handle `systemd` notifications ourselves instead of relying on `systemd-notify`.
* This mitigates an upstream bug which caused Abalone to restart repeatedly.

# v0.4.1

* Corrected param handling when defined as an array in the `config.yaml`.

# v0.4.0

* Add a `:ttl` setting, which lets you reconnect to a running session for a
  given number of seconds after disconnecting. This allows you to resume sessions
  interrupted by network instability, for example.
* Add a menu option to force a terminal reset, e.g. killing & restarting.
* Add a jQuery plugin which makes it trivial to use Abalone in an existing page.
* Add a `:welcome` setting, which puts a message on the *Start Session* overlay.

# v0.3.4

* Added a watchdog when running under systemd.

# v0.3.3

* Added a new `bannerfile` setting.
* Set to:
    * filename to display
    * `false`: no file is displayed
    * `true: display `/etc/issue.net`


# v0.3.2

* Disable X-Frame-Options so this can be easily embedded.

# v0.3.1

* Ensures the environment is somewhat sane.

# v0.3.0

* Adds a timeout counter, allowing a maximum life setting for shells.

# v0.2.1

* Fixed a string encoding issue that could sometimes cause wedged shells.

# v0.2.0

* Added autoconnect setting so you can require users click
  a button to start their session.

# v0.1.1

* Fixed a crashing UTF8 bug
* Added a simple Puppet module for management

# v0.1.0

* Added customization options and documentation.
* Can now run `login`, `ssh`, or a custom command.
* Can use an SSH key for passwordless login.
* Can accept arbitrary whitelisted command arguments.
  * passed to command via parameters, so no shell injection.

# v0.0.1

* Initial release.
