Set an executable permission to service-monitor.sh file.  
$ chmod +x /opt/scripts/service-monitor.sh    

Finally add a cronjob to automate this. It will run every 5 minutes.  
#crontab -e  
*/5 * * * * /bin/bash /opt/scripts/service-monitor.sh  

For every minute  
* * * * * /path/to/script 

