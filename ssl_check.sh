#!/bin/bash
# Requires openssl, bc, grep, sed, date, mutt, sort

## Edit these ##
# Space separated list of domains to check
DOMLIST="google.com facebook.com"
# Send the report
REPORTEMAIL=malkiat.janjua@gmail.com
# Additional alert if domain has less than this number of days before expiry
EXPIRYALERTDAYS=15
# Logfile/report location
LOGFILE=/tmp/SSLreport.txt
## Editing finished ##

# Clear last log
echo "" > $LOGFILE

for DOMAIN in $DOMLIST
do
	EXPIRY=$( echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | sed 's/notAfter=//')
	EXPIRYSIMPLE=$( date -d "$EXPIRY" +%F )
	EXPIRYSEC=$(date -d "$EXPIRY" +%s)
	TODAYSEC=$(date +%s)
	EXPIRYCALC=$(echo "($EXPIRYSEC-$TODAYSEC)/86400" | bc )
	# Output
	if [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ] ;
	then
		echo "######ALERT####### $DOMAIN Cert needs to be renewed." >> $LOGFILE
	fi
	echo "$EXPIRYSIMPLE - $DOMAIN expires (in $EXPIRYCALC days)" >> $LOGFILE
done

# Report
sort -n -o $LOGFILE $LOGFILE 
echo "SSL Report on $(date)" | ssmtp $REPORTEMAIL <$LOGFILE
