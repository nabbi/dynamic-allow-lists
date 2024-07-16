#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"
# nic@boet.cc

# extract cidr networks, which are category "Optimize", for MS O365
# https://docs.microsoft.com/en-us/office365/enterprise/office-365-vpn-implement-split-tunnel#configuring-and-securing-teams-media-traffic

set debug 0
set trace 0

set path [file dirname [file normalize [info script]]]

source $path/inc/common.tcl

set filter [lindex $argv 0]
if { [string length $filter] == 0 } {
    set filter "Optimize Allow"
}

package require json
package require uuid

# https://docs.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-ip-web-service?view=o365-worldwide
set uuid [::uuid::uuid generate]
set host "endpoints.office.com"
set uri "/endpoints/worldwide?clientRequestId=$uuid"

set data [myhttp "https://${host}${uri}"]

## extract the session authentication signature
set json [::json::json2dict $data]

# Microsoft changed the JSON structure on 2021-06-28
# making this appear as a list of dictionaries instead of a dict of dict
# old foreaech: services [dict keys $json] values [dict values $json]

set raw_networks ""
foreach services $json {

    set category [dict get $services category]

    # This allows filtering MS category tags
    foreach f $filter {
        if { [string match $f $category] } {
            if { $trace } { puts "## [dict get $services serviceAreaDisplayName]" }
            if { $trace } { puts "## [dict get $services ips]" }

            foreach cidr [dict get $services ips] {
                lappend raw_networks $cidr
            }
        }
    }
}

set net [validate_networks $raw_networks 75]

set date [clock format [clock seconds] -format "%Y-%m-%d.%H:%M"]
puts "# Microsoft Office365 $date"
foreach n $net {
    puts $n
}

exit
