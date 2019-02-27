# if the feature is turned on for the Distro, we want to FORCE depenency to ensure
# "runit" gets packaged on the target image...
RDEPENDS_${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'runit runit-base-services', '', d)}"

# Set up some default behaviors
RUNIT-SERVICES ??= ""
runit-svcdir = "/etc/sv"
runit-runsvdir = "/etc/runit/runsvdir"

# This class will be included in any recipe that supports runit services configs,
# even if runit is not in DISTRO_FEATURES.  As such don't make any changes
# directly but check the DISTRO_FEATURES first.
python __anonymous() {
    # If the distro features have runit but not sysvinit, inhibit update-rcd
    # from doing any work so that pure-runit based images don't have redundant init
    # files/links.
    if bb.utils.contains('DISTRO_FEATURES', 'runit', True, False, d):
        if not bb.utils.contains('DISTRO_FEATURES', 'sysvinit', True, False, d):
            d.setVar("INHIBIT_UPDATERCD_BBCLASS", "1")
}

# Services specs should be set up in the files under sv in the files directory 
# and specfied at least as a directory (Preferably, each piece part in the 
# tree to support devtool properly) 
install_runit_services() {
    if [ -d ${WORKDIR}/sv ] ; then 
        # Ensure we've got a proper services directory in the packaging...
        mkdir -p ${D}${runit-svcdir}

        cp -rap --no-preserve=ownership ${WORKDIR}/sv/* ${D}${runit-svcdir}
    fi
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'install_runit_services', '', d)} "

# One of the other things we need to do is if we've got a corresponding service in
# the services directory for ${PN}, then we need to nuke the sysvinit entries.
# because we have a service in place.  (We'll handle any init.d entries that are
# left in there, but as people add services for runit in recipes or as the overlays
# in this metadata layer, we want to remove them...)
# 
# FIXME - This just blindly removes everything in the packaging for sysvinit and systemd stuff
#         For now, this is, "fine," but needs to be revisited with "better".
cleanup_sysvinit_dirs() {
    rm -rvf ${D}/etc/rc*.d
    dirlist=`find ${D}/etc/ -type d -name 'init.d' -print`
    dirlist="$dirlist `find ${D}/etc/ -type d -name 'system.d' -print`"
    for dir in $dirlist; do
        rm -rf $dir
    done
}
DO_SYSVINIT_CLEANUP = "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', '', 'cleanup_sysvinit_dirs', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_SYSVINIT_CLEANUP}', '', d)} "

# Services can be enabled in one of two ways or left disabled per package.
#
# In the first way, if you specify "DEFAULT" in all caps in the RUNIT_SERVICES
# list, it will presume everything is to be put in the default runlevel instead
# of "once" runlevel part.
# 
# In the second way, we process it in steps much like we do SERIAL_CONSOLES
# wherein you specify the service name to be enabled, followed by one or more
# optional parameters where you specify "once" for run-once at start and
# "log" to enable service specific logging from the redirected output of the
# daemon binary, with the options being separated by semicolons.
enable_default_services() {
	install -d ${D}${runit-runsvdir}
	install -d ${D}${runit-runsvdir}/once
	install -d ${D}${runit-runsvdir}/default   
    for svc in ${D}${runit-svcdir}; do
        ln -s ${runit-svcdir}/$svc ${D}${runit-runsvdir}/default
    done
}

enable_services() {
	install -d ${D}${runit-runsvdir}
	install -d ${D}${runit-runsvdir}/once
	install -d ${D}${runit-runsvdir}/default   

    # Do this off of what's listed...
    tmp="${RUNIT-SERVICES}"
	for entry in $tmp; do
		svc=`echo $entry | awk -F ";" '{ print $1 }'`
		option1=`echo $entry | awk -F ";" '{ print $2 }'`
		option2=`echo $entry | awk -F ";" '{ print $3 }'`
        
        if [ "$option1" = "once" -o "$option2" = "once" ]; then
            linkpath="once"
        else
            linkpath="default"
        fi
        ln -s ${runit-svcdir}/$svc ${D}${runit-runsvdir}/$linkpath  
        if [ "$option1" = "log" -o "$option2" = "log" ]; then
            # User has specified simple logging support for the service 
            # (Which, technically, can be done out of the sv dir, but
            #  this lets a user specify it even simpler than that way...)
            logsv="${D}${runit-svcdir}/$svc/log"
            mkdir -p $logsv
            logsv="$logsv/run"
            echo "#!/bin/sh" > $logsv
            echo "exec chpst -ulog svlogd -tt $svc" >> $logsv
            chmod a+x $logsv
        fi      
	done
}
DO_DEFAULT_SVCS = "${@bb.utils.contains('RUNIT-SERVICES', 'DEFAULT', 'enable_default_services', 'enable_services', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_DEFAULT_SVCS}', '', d)} "

