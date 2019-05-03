# meta-runit
Provide init services ultimately using either busybox's runit variant or the full-on one.

Currently, the layer, in it's current state of affairs, is using madscientist42's runit fork (Current maintained, using CMake for build and packaging).  Future iterations will use either version depending on needs.  Current source is intended to be used with Sumo.  No promises (yet) on any of the follow-on or prior layer versions.  It is very much an early release of metadata- if it breaks, you get _**ALL**_ of the pieces; all other warranties, implied or expressed are inoperative.  That being said, for what little has been bolted in/on to this as .bbappends to do this more the "right" way than past attempts at this to showcase what runit brings to the table, it seems to work _**WELL**_. _**(REALLY WELL...)**_

_**How to use: (Currently)**_

Add this to your project metadata layer set in whatever manner you see fit and add it to your conf/bblayers.conf file as a valid layer.

Once there, you need only add "runit" to your DISTRO_FEATURES to turn on runit itself along with install the currently provided/supported services.  If you want to run it as a full-on init replacement (C'mon, you _**KNOW**_ you want to...) you need only add "runit-init" to the DISTRO_FEATURES and remove "sysvinit" from them.  This enables the full support currently available for things.

In order to add a package to support this, you need only inherit from runit.bbclass and have the services setup (i.e. /etc/sv/<foo>/run script at minimum) in your SRC_URI set and it will package it accordingly for you and enable it based on rules set in the RUNIT_SERVICES variable in your package declarations as follows:

- If you specify, "DEFAULT" in all caps, in that variable, it will explicitly take each and every sv/<foo> configuration 
- If you specify the names of the services that you want enabled in a space separated list (where the name is <foo> for sv/foo> ) with or without moderators";log" in the mix sets it up for per-service logging.  Order doesn't matter on the modifiers ) it will enable the specified services to launch at boot.

_**Current State of Affairs**_

We have a decent mix of baseline services working in the layer.  This is now something previewable and usable in it's base form along with mminimal mods with your distribution (pha-linux, etc...) to support using Connman and IWD (or not...we reccomend you contemplate that though...).  You will need to add services for the daemons we haven't gotten done yet.  This layer accepts pull requests for anything services-wise that involves meta/meta-poky.  There will be a metadata layer that requires this one that will provide supports for meta-openembedded.  That will accept pull requests for support recipes for those layers.
