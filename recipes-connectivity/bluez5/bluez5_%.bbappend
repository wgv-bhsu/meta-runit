# Extend the search path to here first...
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Add a services set...
SRC_URI += " \
    file://sv/bluetooth/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT_SERVICES = "DEFAULT"