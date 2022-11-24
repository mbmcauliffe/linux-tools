#!/bin/bash

#For use with Debian derivatives

#For vnc, nano /etc/rc.local, add "su - [user] -c '/usr/bin/vncserver :1"

# Identify the drive the Linux instance is running on and its number of partitions
linuxDrive=$(findmnt -n /run/live/medium | awk '{print $2}' | rev | cut -c2- | rev)
numPartitions=$(sudo partx -g $linuxDrive | wc -l)

# Complete actions if the current Linux instance is a Live-Boot
if [ "$linuxDrive" != "mmcblk0" && "$linuxDrive" != "nvme0n1"]
then

	# Create and set up a persistent partition if one does not exist
	if [ "$numPartitions" -lt "3" ]
	then

		#Create Partition
		sudo fdisk $linuxDrive <<< $(printf "n\np\n\n\n\nw")

		#Encrypt and Open Partition
		sudo cryptsetup --verbose --verify-passphrase luksFormat ${linuxDrive}3
		sudo cryptsetup luksOpen ${linuxDrive}3 persistence #Volume

		#Format Partition
		sudo mkfs.ext4 -L persistence /dev/mapper/persistence #FS Label
		sudo e2label /dev/mapper/persistence persistence #System Label

		#Mount, Create .conf, Unmount
		sudo mkdir -p /mnt/persistence
		sudo mount /dev/mapper/persistence /mnt/persistence
		sudo echo "/ union" | sudo tee /mnt/persistence/persistence.conf
		sudo umount /dev/mapper/persistence

		#Close Encryption
		sudo cryptsetup luksClose /dev/mapper/persistence

		#Allow changes to take effect
		reboot

	fi

	# Change the default Live-Boot Password
	passwd

fi

# Security Actions
sudo /etc/ssh/dpkg-reconfigure openssh-server
rootPassword=$(openssl rand -hex 12)
sudo passwd root <<< $(printf "$rootPassword\n$rootPassword")

# Update System
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
sudo timedatectl set-timezone America/Chicago

#Install Packages
sudo apt install git gnupg gnupg2 gnupg1 -y

# Add TOR to APT Repository List
sudo wget -O- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --dearmor | sudo tee /usr/share/keyrings/tor.gpg > /dev/null
sudo printf 'deb [signed-by=/usr/share/keyrings/tor.gpg] https://deb.torproject.org/torproject.org stretch main
deb-src [signed-by=/usr/share/keyrings/tor.gpg] https://deb.torproject.org/torproject.org stretch main' | sudo tee /etc/apt/sources.list.d/tor.list > /dev/null

# Add Sublime Text to APT Repository List
sudo wget -O- https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/sublime.gpg > /dev/null
sudo printf 'deb [signed-by=/usr/share/keyrings/sublime.gpg] https://download.sublimetext.com/ apt/stable/' | sudo tee /etc/apt/sources.list.d/sublime-text.list > /dev/null

# Download and install ProtonVPN Repo
sudo wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/ -r --no-parent -A 'protonvpn-stable-release*.deb' --no-directories -P /tmp/
sudo apt install /tmp/protonvpn-stable-release*.deb

# Update System
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

#Install Packages
sudo apt install git htop protonvpn deb.torproject.org-keyring tor torbrowser-launcher sublime-text tightvncserver ntfs-3g htop gparted xarchiver mupdf nodejs npm firefox gimp libreoffice pulseaudio pavucontrol paprefs bluetooth pulseaudio-module-bluetooth blueman bluez-firmware smplayer nomacs redshift redshift-gtk piper -y

sudo /sbin/modprobe iwlwifi

sudo git config --global credential.helper store

# Update System
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y

# Add a ReadMe file to the user's Desktop
echo 'Use the following installed programs instead of
their windows alternatives:

Video, and Music:
	SMPlayer

Photo:
	Nomacs

Text Editor:
	Sublime Text 3

PDF:
	mupdf

Microsoft Word:
	LibreOffice Writer

Microsoft PowerPoint:
	LibreOffice Impress

Microsoft Excel:
	LibreOffice Calc

Internet:
	Firefox ESR

Zip and RAR:
	Xarchiver

Photo editing:
	GIMP

Cloud storage:
	pCloud

Internet Connection:
	Wicd

Bluetooth:
	Bluetooth Manager

Blue Light Filter:
	Redshift

Partition management:
	GParted

Task Manager:
	htop

Sound:
	PulseAudio

VPN:
	ProtonVPN

Logitech Keyboard and Mouse Control:
	piper' > ~/Desktop/ReadMe.txt

# Initialize Crontab
sudo crontab -l > cronLines

# Write to Crontab
sudo echo "@reboot apt update && apt upgrade -y && apt autoremove -y" > cronLines

# Save Crontab
sudo crontab cronLines

sudo rm -f cronLines
