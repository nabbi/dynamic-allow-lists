#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"
# nic@boet.cc

# extract cidr networks for Cisco Webex services
# https://help.webex.com/en-us/WBX264/How-Do-I-Allow-Webex-Meetings-Traffic-on-My-Network#id_135011

# Cisco modified their webpage 9/2 breaking these updates (althrough they posted updates 8/25 our fetches from on the second)
# Content is hidden under css navigation which curl or wget does not support
#
# This element needs to be removed or changed to "block" (which is the value set with ::after)
#
# #content .stack-container .panel-collapse.collapse, .tabs-content .stack-container .panel-collapse.collapse {
#     display: none;
# }

set debug 0
set trace 0

set path [file dirname [file normalize [info script]]]

source $path/inc/common.tcl

# finding is quick and dirty to call shell code here
# there are CIDR comments in the pages change log, # so try to start matching at that sections header
## curl --silent https://help.webex.com/en-us/WBX264/How-Do-I-Allow-Webex-Meetings-Traffic-on-My-Network#id_135011 | grep -A20 "List of IP address ranges" | grep "(CIDR)"

set data [myhttp "https://help.webex.com/en-US/article/WBX264/How-Do-I-Allow-Webex-Meetings-Traffic-on-My-Network?#id_135010"]

# This should return a one line string
#
# <ul><li>62.109.192.0/18 (CIDR) or 62.109.192.0 - 62.109.255.255 (net range)</li><li>64.68.96.0/19 (CIDR) or 64.68.96.0 - 64.68.127.255 (net range)</li><li>66.114.160.0/20 (CIDR) or 66.114.160.0 - 66.114.175.255 (net range)</li><li>66.163.32.0/19 (CIDR) or 66.163.32.0 - 66.163.63.255 (net range)</li><li>69.26.160.0/19 (CIDR) or 69.26.160.0 - 69.26.191.255 (net range)</li><li>114.29.192.0/19 (CIDR) or 114.29.192.0 - 114.29.223.255 (net range)</li><li>150.253.128.0/17 (CIDR) or 150.253.128.0 - 150.253.255.255 (net range)</li><li>170.72.0.0/16 (CIDR) or 170.72.0.0 - 170.72.255.255 (net range)</li><li>170.133.128.0/18 (CIDR) or 170.133.128.0 - 170.133.191.255 (net range)</li><li>173.39.224.0/19 (CIDR) or 173.39.224.0 - 173.39.255.255 (net range)</li><li>173.243.0.0/20 (CIDR) or 173.243.0.0 - 173.243.15.255 (net range)</li><li>207.182.160.0/19 (CIDR) or 207.182.160.0 - 207.182.191.255 (net range)</li><li>209.197.192.0/19 (CIDR) or 209.197.192.0 - 209.197.223.255 (net range)</li><li>210.4.192.0/20 (CIDR) or 210.4.192.0 - 210.4.207.255 (net range)</li><li>216.151.128.0/19 (CIDR) or 216.151.128.0 - 216.151.159.255 (net range)</li></ul>

set records [split $data "<li><li>"]
set raw_networks ""
foreach r $records {
    if { [string match "*CIDR*" $r] } {
        if { $debug } { puts "r: $r" }

        # April 2023 new entires have non-breaking space
        set r [string map {"&nbsp;" " "} $r]

        set cisco [lindex [split $r " "] 0]

        # returns {net mask} {type}
        # invalid inputs are filtered by function and wont be added to acl as the ipv4 type is missing
        # This protects us against silly duplicate raw dump php code which Cisco posted on this web page
        set nm [netmask $cisco]

        lappend raw_networks $cisco
    }
}

set net [validate_networks $raw_networks 10]

set date [clock format [clock seconds] -format "%Y-%m-%d.%H:%M"]
puts "# Cisco Webex $date"
foreach n $net {
    puts $n
}

exit
