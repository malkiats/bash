#!/bin/bash
# Requires openssl, bc, grep, sed, date, mutt, sort
 
# Space separated list of domains to check
DOMAINLIST=`cat /root/ssl/domain`
 
# Where to send the report
REPORTEMAIL=`cat /root/ssl/report`
 
# Additional alert warning prepended if domain has less than this number of days before expiry
EXPIRYALERTDAYS=50
TENDAYS=10

 
# Logfile/report location
LOGFILE=/var/www/html/sslwatch.html
LOGSTATUS=ssl_expiry.txt
ALERTSTATUS=alert_renew.txt
#LOGFILE=/usr/local/var/www/sslwatch.html
 
# Clear last log
echo "" > $LOGFILE
echo "" > $LOGSTATUS
echo "" > $ALERTSTATUS
cat <<- EOF >> $LOGFILE
 
<!DOCTYPE html>
<html>
<head>
<title>SSL Certificate Monitoring</title>
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
    width: 70%;
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
  background-color: #FFD580;
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
  border-radius:50%;
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
<h1 style=font-family:verdana;color:#231709;text-align:center;> SSL Certificate Monitoring Dashoard</h2>
<h4 style=font-family:verdana;color:#231709;text-align:center;>Updated at - $(date)</h4><br>
<div class=textContainer><input type="text" id="myInput" onkeyup="myFunction()" placeholder="Search for names.." title="Type in a name"></div>

  <div class="vertical-center">
    <button onclick="sortTable()">Click here to Sort</button>
  </div> <br>

<table id=myTable>
<tr class=header>
<th>CERTIFICATE NAME</th>
<th data-th=Driver details><span>VALID FROM</span></th>
<th>EXPIRY DATE</th>
<th>DAYS LEFT</th>
<th>STATUS</th>
<th>ISSUER</th>
</tr>

EOF

OKSTATUS='<i class="circle"; style="background-color:green;"></i>'
WARNSTATUS='<i class="circle" style="background-color:#FFCC00"></i>'
ERRSTATUS='<i class="circle" style="background-color:red"></i>'
NASTATUS='<i class="circle" style="background-color:#808080"></i>'
 
for DOMAIN in $DOMAINLIST
do
	JUSTDOMAIN=$( echo $DOMAIN | cut -d ":" -f1 )
        EXPIRY=$( echo | openssl s_client -servername $JUSTDOMAIN -connect $DOMAIN 2>/dev/null | openssl x509 -noout -dates | grep notAfter | sed 's/notAfter=//')
VALIDFROM=$( echo | openssl s_client -servername $JUSTDOMAIN -connect $DOMAIN 2>/dev/null | openssl x509 -noout -dates | grep notBefore | sed 's/notBefore=//')
        EXPIRYSIMPLE=$( date -d "$EXPIRY" +%F ) ### %F full date; same as %Y-%m-%d
        VALIDSIMPLE=$( date -d "$VALIDFROM" +%F )
  EXPIRYSEC=$(date -d "$EXPIRY" +%s)      ### %s seconds since 2000-01-01 00:00:00 UTC
        TODAYSEC=$(date +%s)
        EXPIRYCALC=$(echo "($EXPIRYSEC-$TODAYSEC)/86400" | bc )
        ISSUER=$(echo | openssl s_client -servername $JUSTDOMAIN -connect $DOMAIN 2>/dev/null | openssl x509 -noout -issuer | sed 's+.*CN=++' | sed 's+.*CN =++')
 # Output

  STATUS=$(if [ $EXPIRYCALC -lt $TENDAYS ] ; then echo $ERRSTATUS; elif [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ] ; then echo $WARNSTATUS; elif [ $EXPIRYCALC -gt $EXPIRYALERTDAYS ] ; then echo $OKSTATUS; else echo $NASTATUS; fi) 

       
echo "  <tr>" >> $LOGFILE
echo "    <td>$JUSTDOMAIN</td>" >> $LOGFILE
echo "    <td>$VALIDSIMPLE</td>" >> $LOGFILE
echo "    <td>$EXPIRYSIMPLE</td>" >> $LOGFILE
echo "    <td style="text-align:center">$EXPIRYCALC</td>" >> $LOGFILE
echo "    <td style="text-align:center">$STATUS</td>" >> $LOGFILE
echo "    <td>$ISSUER</td>" >> $LOGFILE
echo "  </tr>" >> $LOGFILE
 
done
 
echo "</table>" >> $LOGFILE
 
cat <<- EOF >> $LOGFILE
<script>
function myFunction() {
  var input, filter, table, tr, td, i, txtValue,td5,txtValue5;
  input = document.getElementById("myInput");
  filter = input.value.toUpperCase();
  table = document.getElementById("myTable");
  tr = table.getElementsByTagName("tr");
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[0];
    td5 = tr[i].getElementsByTagName("td")[5]
    if (td || td5) {
      txtValue = td.textContent || td.innerText;
      txtValue5 = td5.textContent || td5.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1 || txtValue5.toUpperCase().indexOf(filter) > -1) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    }      
  }
}

function sortTable() {
  var table, rows, switching, i, x, y, shouldSwitch;
  table = document.getElementById("myTable");
  switching = true;
  /*Make a loop that will continue until
  no switching has been done:*/
  while (switching) {
    //start by saying: no switching is done:
    switching = false;
    rows = table.rows;
    /*Loop through all table rows (except the
    first, which contains table headers):*/
    for (i = 1; i < (rows.length - 1); i++) {
      //start by saying there should be no switching:
      shouldSwitch = false;
      /*Get the two elements you want to compare,
      one from current row and one from the next:*/
      x = rows[i].getElementsByTagName("TD")[0];
      y = rows[i + 1].getElementsByTagName("TD")[0];
      //check if the two rows should switch place:
      if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
        //if so, mark as a switch and break the loop:
        shouldSwitch = true;
        break;
      }
    }
    if (shouldSwitch) {
      /*If a switch has been marked, make the switch
      and mark that a switch has been done:*/
      rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
      switching = true;
    }
  }
}

</script>
EOF
echo "  </body>" >> $LOGFILE
echo " </html>" >> $LOGFILE
 

for DOMAIN in $DOMAINLIST
do
	JUSTDOMAIN=$( echo $DOMAIN | cut -d ":" -f1 )
        EXPIRY=$( echo | openssl s_client -servername $JUSTDOMAIN -connect $DOMAIN 2>/dev/null | openssl x509 -noout -dates | grep notAfter | sed 's/notAfter=//')
        EXPIRYSIMPLE=$( date -d "$EXPIRY" +%F )
        EXPIRYSEC=$(date -d "$EXPIRY" +%s)
        TODAYSEC=$(date +%s)
        EXPIRYCALC=$(echo "($EXPIRYSEC-$TODAYSEC)/86400" | bc )
        # Output
        if [ $EXPIRYCALC -lt $EXPIRYALERTDAYS ] ;
        then
                echo "######ALERT####### $JUSTDOMAIN Cert needs to be renewed." >> $LOGSTATUS
        	echo "Expiry Date: $EXPIRYSIMPLE - expires (in $EXPIRYCALC days)" >> $LOGSTATUS
		mailx -s "######ALERT####### SSL Cert Expiring Soon for $DOMAIN" $REPORTEMAIL < $LOGSTATUS
	fi
        	
		echo "$EXPIRYSIMPLE - $DOMAIN expires (in $EXPIRYCALC days)" >> $ALERTSTATUS
	done
 
# Report
sort -n -o $ALERTSTATUS $ALERTSTATUS
#mailx -s "SSL CERT REPORT" $REPORTEMAIL < $ALERTSTATUS
