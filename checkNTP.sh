#!/bin/bash

# 2013-05-28, Remi Bergsma:
# This script checks NTP peer availability. If none are available, it syncs with the hardware clock
# since on the Raspberry Pi, it is more accurate than our system clock. 
# The system clock is used as a fallback in NTP. 
# See for concept: http://blog.remibergsma.com/tag/ntp

# Settings
VERBOSE=yes

# Test our default gateway to find out if we are connected
ping -q -w 1 -c 1 $(ip r | grep default | cut -d ' ' -f 3) > /dev/null 2>&1
gw=$?

if [ $gw -eq 0 ]; then

        MESSAGE="Default gateway reachable, checking NTP peers."
        logger -p daemon.info -t NTPCheck "$MESSAGE"

        if [ "$VERBOSE" = "yes" ]; then
                echo $(date) "$MESSAGE"
        fi

        # Test our NTP peers. As long as at least one is working, it's ok.
        for server in $(grep server /etc/ntp.conf | grep -v "#"| grep -v "127.127.1." | awk {'print $2'})
        do
                MESSAGE="NTP peer $server"
                ntp=$(nmap -sU -p123 -oG - $server | grep Ports | grep open | awk {'print $5'})
                ret=$?
                if [ $ret -eq 0 ] && [ -n "$ntp" ]; then
                        MESSAGE="$MESSAGE does connect OK"
                        REACHABLE=true
                else
                        MESSAGE="$MESSAGE cannot be reached on udp123"
                fi

                logger -p daemon.info -t NTPCheck "$MESSAGE"

                if [ "$VERBOSE" = "yes" ]; then
                        echo $(date) "$MESSAGE"
                fi
                done
else
        MESSAGE="Default gateway NOT reachable, no internet. Skipping NTP peer tests."
        logger -p daemon.info -t NTPCheck "$MESSAGE"

        if [ "$VERBOSE" = "yes" ]; then
                echo $(date) "$MESSAGE"
        fi
fi

# If none of the peers are reachable on udp123 or we have no internet connection
# Then sync the system clock with our hardware clock
if [ -z "$REACHABLE" ]; then
        MESSAGE="No NTP peers could be reached. Syncing system clock with our hardware clock now."
        logger -p daemon.info -t NTPCheck "$MESSAGE"

        if [ "$VERBOSE" = "yes" ]; then
                echo $(date) "$MESSAGE"
        fi
        # Sync hardware clock to system clock
        # This disables NTPd's '11 minute'-mode
        /sbin/hwclock --hctosys --utc
else
        MESSAGE="At least one NTP peer reachable. Our time should be ok, sync hardware clock with system clock to keep it accurate, too."
        logger -p daemon.info -t NTPCheck "$MESSAGE"

        if [ "$VERBOSE" = "yes" ]; then
                echo $(date) "$MESSAGE"
        fi
        # Sync system clock to hardware clock
        # Do it manually, as the '11-minute'-mode may be disabled
        /sbin/hwclock --systohc --utc
fi
                                                    
