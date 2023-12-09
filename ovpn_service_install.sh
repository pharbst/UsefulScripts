# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    ovpn_service_install.sh                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pharbst <pharbst@student.42heilbronn.de>   +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/11/08 09:12:37 by pharbst           #+#    #+#              #
#    Updated: 2023/12/09 03:08:20 by pharbst          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

echo "Enter the name of the config file you want to use:"
read ConfigName
echo "Enter the driectory where the config file is located:"
read WorkingDir
echo "Enter the timeout in seconds:"
read TimeOut

ovpndirectory=/etc/openvpn/client

echo "copying files"
if [ ! -d $ovpndirectory ]; then
	sudo mkdir $ovpndirectory
fi
sudo cp $WorkingDir/$ConfigName $ovpndirectory

echo "#!/bin/bash

WorkingDir=$ovpndirectory
ConfigName=$ConfigName
LogFile=VPN.log
TimeOut=$TimeOut
Done=0

sudo openvpn \$WorkingDir/\$ConfigName >\$WorkingDir/\$LogFile 2>&1 &
openvpn_pid=\$!

# init phase
for ((i = 0; i < TimeOut; i++)); do
	if grep -q \"Initialization Sequence Completed\" \$WorkingDir/\$LogFile; then
		systemd-notify --ready --status=\"Connection established\"
		Done=1
		break
	fi
	sleep 1
done

if [ \"\$Done\" -eq 0 ]; then
	if ps -p \$openvpn_pid > /dev/null; then
		kill \$openvpn_pid
	fi
	exit 1
fi

while ps -p \$openvpn_pid > /dev/null; do
	sleep 15
done

if ps -p \$openvpn_pid > /dev/null; then
	kill \$openvpn_pid
fi

exit 0" > $ovpndirectory/ovpn_service.sh

echo "# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    VPN.service                                        :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pharbst <pharbst@student.42heilbronn.de>   +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2023/11/08 06:54:24 by pharbst           #+#    #+#              #
#    Updated: 2023/12/08 15:44:26 by pharbst          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

[Unit]
Description=OpenVPN Connection Service
After=network.target

[Service]
Type=notify
ExecStart=$ovpndirectory/ovpn_service.sh
Restart=unless-stopped
WorkingDirectory=$ovpndirectory

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/VPN.service
touch $ovpndirectory/VPN.log

# For Testing
chmod 700 /etc/openvpn/client/ovpn_service.sh

# echo "Creating openvpn user"
# sudo useradd -r -s /usr/sbin/nologin openvpn

# echo "Setting permissions"
# chown -R openvpn $ovpndirectory
# chown openvpn $ovpndirectory/VPN.log
# chown openvpn $ovpndirectory/ovpn_service.sh
# chown openvpn $ovpndirectory/$ConfigName
# chmod -R 744 $ovpndirectory
# chmod 644 $ovpndirectory/VPN.log
# chmod 700 $ovpndirectory/ovpn_service.sh
# chmod 400 $ovpndirectory/$ConfigName

# sudo echo 'openvpn ALL=(ALL) NOPASSWD: /etc/openvpn/client/ovpn_service.sh
# openvpn ALL=(ALL) NOPASSWD: /usr/sbin/openvpn' >> /etc/sudoers

sudo systemctl daemon-reload

echo "Service installed"
echo "Commands are as followed:"
echo "sudo systemctl start VPN"
echo "sudo systemctl stop VPN"
echo "sudo systemctl restart VPN"
echo "sudo systemctl status VPN"
echo "sudo systemctl enable VPN"
echo "sudo systemctl disable VPN"
