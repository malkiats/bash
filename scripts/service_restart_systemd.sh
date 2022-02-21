# vi /opt/scripts/service-monitor-2.sh

#!/bin/bash
serv=httpd
sstat=dead
systemctl status $serv | grep -i 'running\|dead' | awk '{print $3}' | sed 's/[()]//g' | while read output;
do
echo $output
if [ "$output" == "$sstat" ]; then
    systemctl start $serv
    echo "$serv service is UP now.!" | mail -s "$serv service is DOWN and restarted now On $(hostname)" daygeek@gmail.com
    else
    echo "$serv service is running"
    fi
done
