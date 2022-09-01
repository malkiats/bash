# vi /opt/scripts/service-monitor-2.sh

#!/bin/bash
serv=httpd
stats=dead
systemctl status $service | grep -i 'running\|dead' | awk '{print $3}' | sed 's/[()]//g' | while read output;
do
echo $output
if [ "$output" == "$stats" ]; then
    systemctl start $serv
    echo "$serv service is UP now.!" | mail -s "$serv service is DOWN and restarted now On $(hostname)" malkiat.janjua@gmail.com
    else
    echo "$serv service is running"
    fi
done
