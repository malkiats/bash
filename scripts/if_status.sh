do
	if [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ] ;
	then
		echo "######ALERT####### $DOMAIN Cert needs to be renewed." >> $LOGFILE
	fi
	echo "$EXPIRYSIMPLE - $DOMAIN expires (in $EXPIRYCALC days)" >> $LOGFILE
done

# Report
sort -n -o $LOGFILE $LOGFILE 
mutt -s "SSL Report on $(date)" $REPORTEMAIL <$LOGFILE
