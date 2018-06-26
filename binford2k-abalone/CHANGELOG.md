# v0.0.9
* Systemd doesn't enforce system-wide max file/proc handles. Set it in the .service file
* See https://fredrikaverpil.github.io/2016/04/27/systemd-and-resource-limits/

# v0.0.8
* Corrected logic for config template, allowing false values to be managed.
* Better management of settings in the params hash.

# v0.0.7
* Adding params for all supported features
  * autoconnect
  * timeout
  * ttl
  * welcome

# v0.0.6
* Adding watchdog support

# v0.0.5
* Hotpatching is never a good idea

# v0.0.4
* Corrects handling of bannerfile option.

# v0.0.3
* Adds bannerfile management

# v0.0.2

* Corrects an issue the the config file template.

# v0.0.1

* Initial release.
