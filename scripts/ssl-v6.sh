#!/bin/bash
# Requires openssl, bc, grep, sed, date, mutt, sort
 
# Space separated list of domains to check
DOMAINLIST=`cat list`
 
 
# Additional alert warning prepended if domain has less than this number of days before expiry
EXPIRYALERTDAYS=30
TENDAYS=15
 
# Logfile/report location
LOGFILE=/var/www/html/sslwatch.html
LOGSTATUS=ssl_expiry.txt

 
# Clear last log
echo "" > $LOGFILE
echo "" > $LOGSTATUS

cat <<- EOF >> $LOGFILE

<!DOCTYPE html>
<html>
<head>
<title>SSL Cert Monitoting</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>

<style>
* {
  box-sizing: border-box;
}

#myInput {
  background-position: 10px 10px;
  background-repeat: no-repeat;
  width: 40%;
  margin: 0px auto;
  font-size: 14px;
  padding: 12px 15px 12px 40px;
  border: 1px solid #ddd;
  margin-bottom: 12px;
}

#myTable {
  border-collapse: collapse;
  width: auto;
  text-align: center;
  border: 1px solid #ddd;
  font-size: 14px;
  margin-left: auto;
  margin-right: auto;
}

#myTable th, #myTable td {
  text-align: left;
  font-family: verdana;
  padding: 12px;
}

#myTable th {
  background-color: #87CEEB;
}

#myTable tr {
  border-bottom: 1px solid #ddd;
}

#myTable tr.header, #myTable tr:hover {
  background-color: #f1f1f1;
}

.textContainer {
  display: flex;
  justify-content: center;
}

.circle {
  height: 25px;
  width: 25px;
  border-radius: 50%;
  display:inline-block;
}

.vertical-center {
  position: absolute;
  margin-left: auto;
  margin-right: auto;
  left: 0;
  right: 0;
  text-align: center;
  -ms-transform: translateY(-50%);
  transform: translateY(-50%);
}

</style>


<br>
<h1 style=font-family:verdana;color:black;text-align:center;> SSL Certificate Monitoring Dashoard</h2>
<h4 align=center>Updated at - $(date)</h4><br>
<div class=textContainer><input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for names.." title="Type in a name">,</div>

<br>

<table id=myTable>

<tr class=header>
<th>CERTIFICATE NAME</th>
<th data-th=Driver details><span>VALID FROM</span></th>
<th>EXPIRY DATE</th>
<th>DAYS LEFT</th>
<th>ALERT</th>
<th>STATUS</th>
<th>SERVER</th>
<th>PROJECT</th>
<th>ISSUER</th>
</tr>

EOF

OKSTATUS='<i class="circle"; style="background-color:green;"></i>'
WARNSTATUS='<i class="circle"; style="background-color:#FFCC00;"></i>'
ERRSTAUS='<i class="circle"; style="background-color:red;"></i>'
NASTATUS='<i class="circle"; style="background-color:gray;"></i>'

for DOMAIN in $DOMAINLIST
do
        SRVENV=$( echo $DOMAIN | cut -d "|" -f2)
        DOMAINPORT=$( echo $DOMAIN | cut -d "|" -f1)
        JUSTDOMAIN=$( echo $DOMAIN | cut -d "|" -f1)
        EMAILREPORT=$( echo $DOMAIN | cut -d "|" -f3)
        ACCT=$( echo $DOMAIN | cut -d "|" -f4)
        EXPIRY=$( echo | openssl s_client -servername $JUSTDOMAIN -connect $DOMAINPORT 2>/dev/null | openssl x509 -noout -dates | grep notAfter | sed 's/notAfter=//')
        VALIDFROM=$( echo | openssl s_client -servername $JUSTDOMAIN -connect $DOMAINPORT 2>/dev/null | openssl x509 -noout -dates | grep notBefore | sed 's/notBefore=//')
        EXPIRYSIMPLE=$( date -d "$EXPIRY" +%F ) ### %F full date; same as %Y-%m-%d
        VALIDSIMPLE=$( date -d "$VALIDFROM" +%F )
      	EXPIRYSEC=$(date -d "$EXPIRY" +%s)      ### %s seconds since 2000-01-01 00:00:00 UTC
        TODAYSEC=$(date +%s)
        EXPIRYCALC=$(echo "($EXPIRYSEC-$TODAYSEC)/86400" | bc )
        ISSUER=$(echo | openssl s_client -servername $JUSTDOMAIN -connect $DOMAINPORT 2>/dev/null | openssl x509 -noout -issuer | sed 's+.*CN=++' | sed 's+.*CN =++')
	
  # Output

if [ $EXPIRYCALC == 0 ];
then
      echo "" > $LOGSTATUS
      echo -e "DOMAIN NAME: $JUSTDOMAIN" >> $LOGSTATUS
      echo "" > $LOGSTATUS
      echo -e "EXPIRY DATE: $EXPIRYSIMPLE (in $EXPIRYCALC days)" >> $LOGSTATUS
      echo "" > $LOGSTATUS
      echo -e "Cert Issue: $ISSUER" >> $LOGSTATUS
      mail -s "CRITICAL ALERT - SSL Cert is Expired for $JUSTDOMAIN" $EMAILREPORT < $LOGSTATUS
elif [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ];
then
      echo "" > $LOGSTATUS
      echo -e "DOMAIN NAME: $JUSTDOMAIN" >> $LOGSTATUS
      echo "" > $LOGSTATUS
      echo -e "EXPIRY DATE: $EXPIRYSIMPLE (in $EXPIRYCALC days)" >> $LOGSTATUS
      echo "" > $LOGSTATUS
      echo -e "Cert Issue: $ISSUER" >> $LOGSTATUS
      mail -s "CRITICAL ALERT - SSL Cert is Expiring soon for $JUSTDOMAIN" $EMAILREPORT < $LOGSTATUS
fi


STATUS=$(if [ $EXPIRYCALC -lt $TENDAYS ] ; then echo $ERRSTATUS; elif [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ] ; then echo $WARNSTATUS; elif [ $EXPIRYCALC -gt $EXPIRYALERTDAYS ] ; then echo $OKSTATUS; else echo $NASTATUS; fi)
STATUSW=$(if [ $EXPIRYCALC -lt $TENDAYS ] ; then echo ERROR; elif [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ] ; then echo WARNING; elif [ $EXPIRYCALC -gt $EXPIRYALERTDAYS ] ; then echo OK; else echo NO STATUS; fi)

        
echo "  <tr>" >> $LOGFILE
echo "    <td>$JUSTDOMAIN</td>" >> $LOGFILE
echo "    <td>$VALIDSIMPLE</td>" >> $LOGFILE
echo "    <td>$EXPIRYSIMPLE</td>" >> $LOGFILE
echo "    <td style="text-align:center">$EXPIRYCALC</td>" >> $LOGFILE
echo "    <td style="text-align:center">$STATUS</td>" >> $LOGFILE
echo "    <td>$STATUSW</td>" >> $LOGFILE
echo "    <td>$SRVENV</td>" >> $LOGFILE
echo "    <td>$ACCT</td>" >> $LOGFILE
echo "    <td>$ISSUER</td>" >> $LOGFILE 
echo "  </tr>" >> $LOGFILE

done

echo "</table>" >> $LOGFILE

cat <<- EOF >> $LOGFILE
<script>
function myFunction() {
  var input, filter, table, tr, td, i, txtValue;
  input = document.getElementById("myInput");
  filter = input.value.toUpperCase();
  table = document.getElementById("myTable");
  tr = table.getElementsByTagName("tr");
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[0];
    if (td) {
      txtValue = td.textContent || td.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    }       
  }
}

</script>

EOF

echo "  </body>" >> $LOGFILE
echo " </html>" >> $LOGFILE
