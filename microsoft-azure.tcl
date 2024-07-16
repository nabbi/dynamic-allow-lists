#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"
# nic@boet.cc

# Microsoft Azure Datacenter IP Ranges

set debug 0
set trace 0

set path [file dirname [file normalize [info script]]]

source $path/inc/common.tcl

package require json

# This is a two step download process
# Confirm the download to get the real json link
set data [myhttp "https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519"]

foreach line [split $data "\n"] {
    if { [string match "*https://*.json*" $line] } {
        regexp -nocase {http.*json} $line link
        # filter out garbage
        if { ! [string match "*<*" $link] } {
            if { $trace } { puts "## download link $link" }
            break
        }
    }
}

# this second fetch contains the json payload
set data [myhttp $link]

## extract the session authentication signature
set json [::json::json2dict $data]
set azure [dict get $json "values"]

set raw_networks ""
foreach az $azure {
    set properties [dict get $az properties]

    if { [dict exists $properties addressPrefixes] } {
        if { $trace } { puts "## [dict get $properties systemService]" }
        if { $trace } { puts "## [dict get $properties addressPrefixes]" }

        foreach cidr [dict get $properties addressPrefixes] {
            lappend raw_networks $cidr
        }
    }
}

# disabled validations as this tool ~90 seconds locked at 40% core utilizations
# We are parsing good JSON data and not dirty HTML so we should be okay
# set net [validate_networks $raw_networks]
if { [llength $raw_networks] < 70000 } {
    myerror "list contained fewer valid networks or hosts than expected"
}

set date [clock format [clock seconds] -format "%Y-%m-%d.%H:%M"]
puts "# Microsoft Azure $date"
foreach n $raw_networks {
    puts $n
}

exit
