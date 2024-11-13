#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"
# nic@boet.cc

# extract cidr networks for Zoom
# https://support.zoom.us/hc/en-us/articles/360053610731-VPN-Split-Tunneling-Recommendations?mobile_site=true

set debug 0
set trace 0

set path [file dirname [file normalize [info script]]]

source $path/inc/common.tcl

set data [myhttp "https://assets.zoom.us/docs/ipranges/ZoomMeetings.txt"]

set raw_networks ""
foreach line [split $data "\n"] {
    if { $debug } { puts "r: $line" }
    lappend raw_networks [lindex [split $line " "] 0]
}

set net [validate_networks $raw_networks 25]

set date [clock format [clock seconds] -format "%Y-%m-%d.%H:%M"]
puts "# Zoom $date"
foreach n $net {
    puts $n
}

exit
