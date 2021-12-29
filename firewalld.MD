firewall-cmd --state

firewall-cmd --get-default-zone
firewall-cmd --list-all
firewall-cmd --get-zones

firewall-cmd --zone=public --add-port=5000/tcp
firewall-cmd --zone=public --list-ports
firewall-cmd --zone=public --add-port=4990-4999/udp

sudo firewall-cmd --zone=public --permanent --add-port=5000/tcp
sudo firewall-cmd --zone=public --permanent --add-port=4990-4999/udp
sudo firewall-cmd --zone=public --permanent --list-ports

firewall-cmd --reload
firewall-cmd --get-services  

![image](https://user-images.githubusercontent.com/43002915/147619192-3431c8bd-ab0c-46ad-9358-6a263a3950d1.png)
