cat sap-modified.list | while read n; do echo -n "$n: "; ssh -nq $n "mount /oracle/backup; df -h /oracle/backup"; done
