# LVM and LUKS
## Goal 
to set up LUKS on top of LVM using:
- Arch Linux
- in VirtualBox
- with UEFI enabled

to activate UEFI in VirtualBox:  
Settings> System, and tick "Enable EFI..."

## Step 1: Create Boot Partition
*note: the boot partition cannot be within the LVM or LUKS. It must be "naked," on the disk itself.*

1. Create a small partition (300M) on one of the disks available to the LVM pool. Use the [`fdisk`](./fdisk-tips.md) utility. (In the end, one of the disks should have two partitions, one with 300M, and the 2nd partition extending to the rest of the disk)
1. Format that partition as FAT filesystem:  
`mkfs.fat -F 32 /dev/sda1`

## Step 2: Create Physical Volumes that Underlie the LVM
`pvcreate /dev/sda2`  
(that's the rest of that disk we've already used to create a boot partition)

`pvcreate /dev/sd{b,c}`

**pv = physical volume*

## Step 3: Create Volume Group using the PVs

create it first from one of the PVs:  
`vgcreate vg01 /dev/sda2`

**It doesn't have to be `vg01`, it can be anything you choose to name it.*

Then add to the volume group just created:  
`vgextend vg01 /dev/sd{b,c}`

## Step 4: Create Logical Volumes out of the Volume Group

- `lvcreate -L 7G -n cryptroot vg01`
- `lvcreate -L 7G -n crypthome vg01`
- `lvcreate -L 4G -n cryptswap vg01`

*The size can be anything of course (*`G` *for gigabytes). The names (set with* `-n`*) can be anything.*

## Make Encrypted Root Using One of the Logical Volumes

- `cryptsetup luksFormat /dev/vg01/cryptroot`

- open the encrypted partition to be able to work with it:  
`cryptsetup open /dev/vg01/cryptroot root`

- make the ext4 (or btrfs) filesystem for the root LV  
`mkfs.ext4 /dev/mapper/root`

## Mount the Root and Boot Partitions

`mount /dev/mapper/root /mnt`  
`mount --mkdir /dev/sda1 /mnt/boot`

## Set up Encrypted Swap

`cryptsetup luksFormat /dev/vg01/cryptswap`  
`cryptsetup open /dev/vg01/cryptswap swap`  
`mkswap /dev/mapper/swap`


enable the swap  
`swapon /dev/mapper/swap`

## Install Basic System

`pacstrap -K /mnt base linux linux-firmware grub efibootmgr nano lvm2 dhcpcd sudo`


## Setting up Encrypted Home
create keyfile (so that you don't have to type a password for home as well):  
`mkdir -m 700 /mnt/etc/luks-keys`

`dd if=/dev/random of=/mnt/etc/luks-keys/home bs=1 count=256 status=progress`

`cryptsetup luksFormat -v /dev/vg01/crypthome /mnt/etc/luks-keys/home`

`cryptsetup -d /mnt/etc/luks-keys/home open /dev/vg01/crypthome home`

`mkfs.ext4 /dev/mapper/home`

`mount /dev/mapper/home /mnt/home`

## Create Fstab

`genfstab /mnt >> /mnt/etc/fstab`

*This creates a fstab not with UUIDs but with `/dev/mapper/*`* 

## Chroot
`arch-chroot /mnt`

## Edit the Crypttab

`nano /etc/crypttab`

1. uncomment "home" and "swap" lines
2. change device location to  
`home /dev/vg01/crypthome`
3. change password for home to:  
`/etc/luks-keys/home`
4. change device location to:  
`swap /dev/vg01/cryptswap`

## Set Time Zone
`ln -sf /usr/share/zoneinfo/`*Region*`/`*City* `/etc/localtime`

`hwclock --systohc`

## Localization
- `nano /etc/locale.gen`

*search for "US" using CTRL-W, press enter to search, then ALT-W fo rhte next instances in search*

- uncomment `en_US.UTF-8`

- run `locale-gen`
- `echo "Lang=en_US.UTF-8" >> /etc/locale.conf`

## Hostname
`echo` *"hostname"* `>> /etc/hostname`

## Edit mkinitcpio

This is so that on boot, LVM is recognized first, followed by LUKS

run `nano /etc/mkinitcpio.conf`

find uncommented "Hooks" line. Between "block" and "filesystems" add "lvm2" and "encrypt" (in that order)

run `mkinitcpio -P`

## Create Root Password

`passwd`

## GRUB Configuration

In the file XXXXX, between the quotes on the line `GRUB_CMDLINE_LINUX=""` write:  
`cryptdevice=/dev/vg01/cryptroot:root root=/dev/mapper/root`

run:  
`grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB`

then run:  
`grub-mkconfig -o /boot/grub/grub.cfg`  

## Finishing Base Setup

exit and reboot  
it should now work

## Further Tweaks

- enable wifi
	1. `systemctl enable dhcpcd`
	2. restart
	
- create user
	+ `useradd -m -G wheel bd`
	+ `passwd bd`
	+ uncomment `%wheel ALL=(ALL:ALL) ALL` in /etc/sudoers
	
- disable root
	+ `sudo passwd -l root`














