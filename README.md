raspberry-pi-ntp-check
======================

This script checks NTP peer availability. If none are available, it syncs with the hardware clock
since it is more accurate than our system clock. The system clock is used as a fallback in NTP.

It is mainly used in my tests to find out if the Raspberry Pi is able to serve a stable NTP clock.

More info in an upcoming blogpost @ http://blog.remibergsma.com
