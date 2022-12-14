echo "Enter the partition's location:"
read partition

#Encrypt and Open Partition
sudo cryptsetup --verbose --verify-passphrase luksFormat $partition
sudo cryptsetup luksOpen $partition encrypted #Volume

#Format Partition
sudo mkfs.ext4 -L encrypted /dev/mapper/encrypted #FS Label
sudo e2label /dev/mapper/encrypted encrypted #System Label

#Close Encryption
sudo cryptsetup luksClose /dev/mapper/encrypted