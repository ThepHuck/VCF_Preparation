# Getting started

These scripts help with prepping & redeploying VCF.  **PowerCLI** is needed for the scripts.  **posh-ssh** is needed for wipe partitions and VCF host prep scripts.  Run `Install-Module posh-ssh -Scope CurrentUser` to install posh-ssh.
- If you're recoverying from a failed VCF deployment, run host wipe to clear the vSAN datastore & disk partitions before rebuilding/reinstalling ESXi
- If you're using automation to reinstall ESXi, using `clearpart --alldrives` in a kickstart file will wipe the disks.  Otherwise the wipe partitions script will clean out the vSAN partitions on the disks after you've reinstalled ESXi.
- Host Prep is used to set specific config to prepare for bring up after a fresh install of ESXi.



## Leave vSAN
**Use this script before reinstall of ESXi**

This is a simple script you can copy & paste into a terminal to force the host to leave the vSAN cluster, and then delete all disk groups.
It stops all running VMs and removes from inventory.  This is useful in case you have the cloud builder VM on a local datastore with snapshots.  After you reinstall ESXi, you can import the VMX file and restore from snapshot.

## Wipe partitions
**Use this script if vSAN was not wiped before reinstall of ESXi**

This script is needed if you've reinstalled ESXi without properly leaving a vSAN cluster or deleting the vSAN disk group from the ESXi host and vSAN partitions are left on the disks.

You may need to edit the command to meet your needs for the disks.  The servers this was written for has the OS on M.2 drives, NVMe cache disks, and SAS capacity disks.

## VCF host prep

This is a simple script you can copy & paste into a terminal to set some of the required configuration for VCF.
- Optionally sets the hostname fqdn to the name supplied in the array, uncomment the three lines to set host fqdn (this is needed if the hostname is still localhost from a manual install)
- Sets DNS servers, network domain name & search domains
- Adds NTP server
- Enables & starts ssh 
- Enables & starts ntpd
- Regenerates certificates & reboots
