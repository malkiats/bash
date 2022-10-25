#!/bin/bash
# Requires openssl, bc, grep, sed, date, mutt, sort
 
# Space separated list of domains to check
DOMAINLIST="AJITJALANDHAR.COM APPLE.COM AWS.COM IBM.COM DELL.COM DXC.COM HP.COM ORACLE.COM"
 
# Where to send the report
REPORTEMAIL=malkiat.janjua@gmail.com
 
# Additional alert warning prepended if domain has less than this number of days before expiry
EXPIRYALERTDAYS=30
 
# Logfile/report location for html and plain text for email
LOGFILE=/var/www/html/sslwatch.html
LOGSTATUS=ssl_expiry.txt

#LOGFILE=/usr/local/var/www/sslwatch.html

#Status
OKYES=ok
OKNOT="Not Ok"
 
# Clear last log
echo "" > $LOGFILE
echo "" > $LOGSTATUS
cat <<- EOF >> $LOGFILE

<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
* {
  box-sizing: border-box;
}

#myInput {
  background-image: url('/css/searchicon.png');
  background-position: 10px 10px;
  background-repeat: no-repeat;
  width: 100%;
  font-size: 16px;
  padding: 12px 20px 12px 40px;
  border: 1px solid #ddd;
  margin-bottom: 12px;
}

#myTable {
  border-collapse: collapse;
  width: 100%;
  border: 1px solid #ddd;
  font-size: 18px;
}

#myTable th, #myTable td {
  text-align: left;
  padding: 12px;
}

#myTable tr {
  border-bottom: 1px solid #ddd;
}

#myTable tr.header, #myTable tr:hover {
  background-color: #f1f1f1;
}
</style>
</head>
<body>

<br>
<h1 style=font-family:verdana;color:black;text-align:center;> SSL Certificate Monitoring Dashoard</h2>
<h4 align=center>Updated at - $(date)</h4><br>
<input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for names.." title="Type in a name">

EOF

echo "<table id=myTable>" >> $LOGFILE  
echo "  <tr class=header>" >> $LOGFILE
echo "    <th>CERTIFICATE NAME</th>" >> $LOGFILE
echo "    <th data-th=Driver details><span>VALID FROM</span></th>" >> $LOGFILE
echo "    <th>EXPIRY DATE</th>" >> $LOGFILE
echo "    <th>DAYS LEFT</th>" >> $LOGFILE
echo "    <th>STATUS</th>" >> $LOGFILE
echo "    <th>ISSUER</th>" >> $LOGFILE
echo "  </tr>" >> $LOGFILE

for DOMAIN in $DOMAINLIST
do
        EXPIRY=$( echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | sed 's/notAfter=//')
VALIDFROM=$( echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates | grep notBefore | sed 's/notBefore=//')
        EXPIRYSIMPLE=$( date -d "$EXPIRY" +%F ) ### %F full date; same as %Y-%m-%d
        VALIDSIMPLE=$( date -d "$VALIDFROM" +%F )
	EXPIRYSEC=$(date -d "$EXPIRY" +%s)      ### %s seconds since 2000-01-01 00:00:00 UTC
        TODAYSEC=$(date +%s)
        EXPIRYCALC=$(echo "($EXPIRYSEC-$TODAYSEC)/86400" | bc )
        ISSUER=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -issuer | sed 's+.*CN=++' | sed 's+.*CN =++')
	# Output
	STATUS=$(if [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ] ; then echo $OKNOT; else echo $OKYES; fi)
	echo "$EXPIRYSIMPLE - $DOMAIN expires (in $EXPIRYCALC days)" >> $LOGSTATUS
echo "  <tr>" >> $LOGFILE
echo "    <td>$DOMAIN</td>" >> $LOGFILE
echo "    <td>$VALIDSIMPLE</td>" >> $LOGFILE
echo "    <td>$EXPIRYSIMPLE</td>" >> $LOGFILE
echo "    <td>$EXPIRYCALC</td>" >> $LOGFILE
echo "    <td>$STATUS</td>" >> $LOGFILE
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
ssmtp -v $REPORTEMAIL < $LOGSTATUS
