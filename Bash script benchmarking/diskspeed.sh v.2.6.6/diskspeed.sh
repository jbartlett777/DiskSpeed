#!/bin/bash

echo
echo "diskspeed.sh for UNRAID, version 2.6.6"
echo "By John Bartlett. Support board @ limetech: http://goo.gl/ysJeYV"
echo

# Version 2.6.6
# Modified to work under UNRAID 7.x
# Fixed the missing disk-capacity values that caused the reported awk syntax errors.
# Added fallback capacity detection using fdisk when hdparm cannot retrieve capacity information.
# Updated the affected awk statements to pass numeric values using -v.
# Improved compatibility with different versions of GNU dd when extracting benchmark speeds.
# Added validation to prevent invalid disk offsets and throughput calculations.
#
# Version 2.6.5
# bonienl modified to work under unRAID 6.4.x 
#
# Version 2.6.4
# Added support for UNRAID version 6.3.0-RC9 & higher.
#
# Version 2.6.3
# Changed memory check to ignore cache memory
#
# Version 2.6.2
# Added a check to ensure there is enough free memory available to execute the
#   dd command
# Added -n | --include option to specify which drives to test, comma delimited
# Ignore floppy drives
# Added support for nvme drives
#
# Version 2.6.1
# Fixed issue identifying drives assigned sdxx (more than 26 drives attached)
# Fixed issue with data drives over 9 having the last digit truncated
#
# Version 2.6
# Removed checks for invalid drives, redundent
# Altered drive inventory to exclude md? drives/identify drive/cache/parity
#   assignments
# Modified to support UNRAID 6.2 running under OS 4.4.x and higher
#
# Version 2.5
# Fixed computation for percentages less than 10%
# Reverted to 1 GB scans for better results but slower
# Added -f --fast to scan 200 MB instead of 1 GB, same as version 2.3 & 2.4
#
# Version 2.4
# If the drive model is not able to be determined via fdisk, extract it from mdmcd
# Add -l --log option to create the debug log file diskspeed.log
# Modified to not display the MB sec in drive inventory report for excluded drives
# Modified to compute the drive capacity from the number of bytes UNRAID reports for
#   external drive cards.
# Added -g --graph option to display the drive by percentage comparison graph
# Added warning if files on the array are open which could mean drives are active
# Added spin up drive support by reading a random spot on the drive
#
# Version 2.3
# Changed to use the "dd" command for speed testing, eliminates risk of hitting
#   the end of the drive. The app will read 200MB of data at each testing location.
# Before scanning each spot, uses the "dd" command to place the drive head at the
#   start of the test location.
# Added -o --output option for saving the file to a given location/name (credit pkn)
# Added report generation date & server name to the end of the report (credit pkn)
# Added a Y axis floor of zero to keep the graph from display negative ranges
# Hid graph that compared each drive by percentage. If you wish to re-enable it,
#   change the line "ShowGraph1=0" to "ShowGraph1=1"
# Added average speed to the drive inventory list below the graph
# Added -x --exclude option to ignore drives, comma seperated. Ex: -x sda,sdb,sdc
# Added -o --output option to specify report HTML file name
#
# Version 2.2
# Changed method of identifying the UNRAID boot drive and/or USB by looking for
#   the file /bzimage or /config/ident.cfg if the device is mounted
# Skip drives < 25 GB
# Route fdisk errors to the bit bucket
# Removed the max size on the 2nd graph to allow smaller drives to scale if larger
#   drives are hidden
#
# Version 2.1
# Fixed GB Size determination to minimize hdparm hitting the end of the drive while
#   performing a read test at the end of the drive (credit doron)
# Fixed division error in averaging sample sizes (credit doron)
# Updated graphs to size to 1000 px wide but shrinkable
# Added 2nd graph which shows drive speeds in relation to the largest drive size; this
#   is a better indication of how your parity speeds may run
# Added drive identification details below the graphs
# Added support for scanning all hard drives attached to the system
#
# Version 2.0
# Added ability to specify the number of tests performed at each sample spot
# Added ability to specify the number of samples to take, min of 3 samples. first sample
#   will be at the start of the drive, last sample at the end, and the rest spread out
#   evenly on the drive
# Added help screen
# Formatted the graph tool tip to display the information in a easy to read format
# Do not run if the parity sync is in process
# Added support for gaps in drive assignments
# Added support for arrays with no parity drive
#
# Version 1.1
# Fix bug for >= 10 drives in array (credit bonienl)
# Fix graph bug so graph displays in MB
#
# Version 1.0
# Initial Release

iterations=1
samples=11
showhelp=0
outputfile="diskspeed.html"
skipdrives=""
include=0
includedrives=""
unraid=""
ShowGraph1=0
log=0
fast=0

numargs=$#
for ((i=1 ; i <= numargs ; i++))
do
	case "$1" in
		-i | --iterations)
			iterations="$2"
			shift 2
			;;
		-s | --samples)
			samples="$2"
			shift 2
			;;
		-o | --output)
			outputfile="$2"
			shift 2
			;;
		-x | --exclude)
			skipdrives="$2"
			shift 2
			;;
		-h | --help)
			showhelp=1
			shift
			;;
		-g | --graph)
			ShowGraph1=1
			shift
			;;
		-l | --log)
			log=1
			shift
			;;
		-f | --fast)
			fast=1
			shift
			;;
		-n | --include)
			include=1
			includedrives="$2"
			shift 2
			;;
	esac
done

# Test to see if the output file specified is writeable
testoutput=""
echo "Test abc123" > "$outputfile.tmp"
if [ -e "$outputfile.tmp" ]; then
	testoutput=$(cat "$outputfile.tmp")
	rm "$outputfile.tmp"
fi
if [ "Test abc123" != "$testoutput" ];then
	echo "Error: Unable to write to $outputfile"
	exit 1
fi

if [[ $showhelp -eq 1 ]]; then
	echo "Syntax: diskspeed.sh -i # -s #"
	echo "        diskspeed.sh --iterations # --samples #"
	echo
	echo "-i, --iterations: Number of tests to take at each location, result is averaged"
	echo "                  Default: 1"
	echo "-s, --samples:    Number of samples taken at evenily distributed locations on"
	echo "                  the hard drive with the first sample at 0GB (start) and the"
	echo "                  last sample at the end of the drive."
	echo "                  Default: 11 (0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100%)"
	echo "-o, --output:     Generate HTML report to specified path/file"
	echo "                  Default: diskspeed.html"
	echo "-x, --exclude:    Drives to skip, comma seperated. Example: sda,sdd,sdk"
	echo "                  Default: boot/unraid drives, under 25GB"
	echo "-n, --include:    Comma delimited list of drives to test, all others excluded"
	echo "-h, --help:       Displays help/syntax (this)"
	echo "-l, --log:        Create a debug log file named 'diskspeed.log'"
	echo "-f, --fast:       Scan 200MB at each location instead of 1GB. Less accurate."
	echo
	exit 0
fi

# Check to see if there is enough free RAM available to execute the dd command
FreeMem=$(cat /proc/meminfo | grep MemAvailable | awk '{print $2}')
if [[ $fast -eq 0 ]]; then
	if [[ $FreeMem -lt 1048576 ]]; then
		echo "Error: There is not enough free memory to perform the disk read test."
		echo "1048576 k required (1 GB), $FreeMem k available."
		if [[ $FreeMem -gt 20480 ]]; then
			echo "You have enough free RAM to execute with the fast (-f --fast) command flag."
		fi
		exit 1
	fi
fi
if [[ $fast -eq 0 ]]; then
	if [[ $FreeMem -lt 20480 ]]; then
		echo "Error: There is not enough free memory to perform the disk read test."
		echo -n "20480k required, $FreeMem"
		echo "k available."
		exit 1
	fi
fi

# See if the array is in use
lsof 2>/dev/null | grep "/mnt/disk[0-9]*/" > /tmp/lsof.txt
if [[ -s /tmp/lsof.txt ]]; then
	echo "Warning: Files in the array are open. Please refer to /tmp/lsof.txt for a list"
	echo
else
	rm /tmp/lsof.txt
fi

cp /proc/mdstat /tmp
mdNumDisabled=$(grep "mdNumDisabled=" /tmp/mdstat)
mdNumInvalid=$(grep "mdNumInvalid=" /tmp/mdstat)
mdNumMissing=$(grep "mdNumMissing=" /tmp/mdstat)
sbNumDisks=$(grep "sbNumDisks=" /tmp/mdstat)
mdResyncPos=$(grep "mdResyncPos=" /tmp/mdstat)

mdNumDisabled=${mdNumDisabled:14}
mdNumInvalid=${mdNumInvalid:13}
mdNumMissing=${mdNumMissing:13}
mdResyncDb=${mdResyncDb:11}
sbNumDisks=${sbNumDisks:11}
mdResyncPos=${mdResyncPos:12}

if [[ $log -eq 1 ]]; then
	echo "ndNumDisabled: $ndNumDisabled" > diskspeed.log
	echo "mdNumInvalid: $mdNumInvalid" >> diskspeed.log
	echo "mdNumMissing: $mdNumMissing" >> diskspeed.log
	echo "mdResyncDb: $mdResyncDb" >> diskspeed.log
	echo "sbNumDisks: $sbNumDisks" >> diskspeed.log
	echo "mdResyncPos: $mdResyncPos" >> diskspeed.log
fi

if [[ $include -eq 1 ]] && [[ $skipdrives != "" ]]; then
	echo "Error: You can only specify to include or exclude drives, not both at the same time"
	exit 1
fi

if [[ $mdNumMissing -ne 0 ]];then
	echo "Error: There are missing drives in the array"
	exit 1
fi
if [[ $mdResyncPos -ne 0 ]];then
	echo "Error: Parity sync is in progress, please wait until the pairty sync process is complete"
	exit 1
fi
re='^[0-9]+$'
if ! [[ $iterations =~ $re ]]; then
   echo "Error: Iteration value must be numeric"
   exit 1
fi
if ! [[ $samples =~ $re ]]; then
   echo "Error: Samples value must be numeric"
   exit 1
fi
if [[ $iterations -lt 1 ]]; then
	echo "Error: Iterations count must be greater than zero"
	exit 1
fi
if [[ $samples -lt 3 ]]; then
	echo "Error: Sample count must be greater than or equal to 3"
	exit 1
fi

# Identify OS version
tmp=$(uname -a | awk '{print $3}')
OS=(${tmp//./ })
CMDVer=0
if [[ ${OS[0]} -ge 4 ]] && [[ ${OS[1]} -ge 4 ]]; then
	CMDVer=1
fi

# Cursor up ANSI
CurUp="\033[1A"


# Get a list of UNRAID variables which contains drive information
wget --quiet --output-document=/tmp/diskspeedvars.txt http://localhost/Tools/Vars
# Init variables
FoundArray=0
InDiskInfo=0
EndScan=0
i=-1
# List of drive attributes to extract, pipe delimited with leading & trailing pipe
# Array variables will be named "Disk_[attrib]" - for example, "Disk_name" and "Disk_id"
# Remove/Add attributes you want, "device" is required below
Attribs="|id|idx|device|name|size|status|temp|numReads|numWrites|numErrors|format|type|fsSize|fsFree|"

# Loop over the Vars HTML
while read line
do
	# Unescape HTML included in 6.3.0 RC-9
	line="${line/&gt;/>}"
	line="${line/&lt;/<}"
	# Check to see if we're past the drive section
	if [[ ${line:0:9} == "[display]" ]]; then
		EndScan=1
	fi
	if [[ $EndScan == 0 ]]; then
		# Check to see if we've found the start of the drive information
		if [[ $FoundArray -eq 0 ]]; then
			if [[ $line == "[disks] => Array" ]]; then
				FoundArray=1
			fi
		else
			# Check to see if we're at the start of a new drive
			if [[ $InDiskInfo -eq 0 ]]; then
				IsParity2=0
				if [[ ${line:0:7} == "[parity" ]] || [[ ${line:0:5} == "[disk" ]] || [[ ${line:0:6} == "[cache" ]]; then
					InDiskInfo=1
					let i++
				fi
				if [[ ${line:0:7} == "[disk1]" ]]; then
					i=2
				fi
				if [[ ${line:0:9} == "[parity2]" ]]; then
					IsParity2=1
				fi
			fi
			# Check to see if we're at the end of a drive's information
			if [[ $InDiskInfo -eq 1 ]] && [[ $line == ")" ]]; then
				InDiskInfo=0
			fi
			# If we're in the middle of a drive's information, log the data
			if [[ $InDiskInfo -eq 1 ]]; then
				tmp=($line)
				CurrVar=${tmp[0]//[\[\]]/}
				CurrVal=${tmp[2]}
				# If temp attribute, check for strange length and override if the temp is reported as "*" and bash evalutes it strange
				if [[ $CurrVar == "temp" ]] && [[ ${#CurrVal} -gt 3 ]]; then
					CurrVal="N/A"
				fi
				if [[ $Attribs =~ "|$CurrVar|" ]]; then
					if [[ $IsParity2 -eq 0 ]]; then
						eval "tmpDisk_$CurrVar[i]=$CurrVal"
					else
						eval "tmpDisk_$CurrVar[1]=$CurrVal"
					fi
				fi
			fi
		fi
	fi
done < /tmp/diskspeedvars.txt
rm /tmp/diskspeedvars.txt

# Rebuild Arrays to remove empty drive assignments
AttribArray=(${Attribs//|/ })
q=-1
for (( d=0; d <= $i; d++ ))
do
	if [[ ${tmpDisk_device[d]} != "" ]]; then
		let q++
		for f in "${AttribArray[@]}"
		do
			if [[ "$f" == "size" ]]; then
				eval "Bytes=\${tmpDisk_$f[$d]}"
				if [[ $Bytes -ge 1048576 ]]; then
					tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1048576}')
					tmp2="MB"
				fi
				if [[ $Bytes -ge 1073741824 ]]; then
					tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1073741824}')
					tmp3=$(awk -v value="$Bytes" 'BEGIN {printf "%0.0f", value / 1073741824}')
					tmp2="GB"
				fi
				if [[ $Bytes -ge 1099511627776 ]]; then
					tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1099511627776}')
					tmp3=$(awk -v value="$Bytes" 'BEGIN {printf "%0.0f", value / 1073741824}')
					tmp2="TB"
				fi
				if [[ "${tmp:(-2)}" == ".0" ]]; then
					tmp=${tmp::-2}
				fi
				Disk_capacity[$q]="$tmp $tmp2"
			fi
			eval "Disk_$f[$q]=\${tmpDisk_$f[$d]}"
		done
	fi
done

UNRAIDDrives=$q

if [[ $log -eq 1 ]]; then
	echo "UNRAID Drive extraction report" >> diskspeed.log
	for (( d=0; d <= $UNRAIDDrives; d++ ))
	do
		echo "${Disk_name[d]} (${Disk_device[d]}) ID [${Disk_id[d]}] Size [${Disk_size[d]}] Status [${Disk_status[d]}]" >> diskspeed.log
	done
	echo "==========" >> diskspeed.log
fi


fdisk -l > /tmp/inventory1.txt 2> /dev/null
if [[ $log -eq 1 ]]; then
	echo "/tmp/inventory1.txt" >> diskspeed.log
	echo "==========" >> diskspeed.log
	cat /tmp/inventory1.txt >> diskspeed.log
	echo "==========" >> diskspeed.log
fi
grep "Disk /" /tmp/inventory1.txt > /tmp/inventory2.txt
sort /tmp/inventory2.txt -o /tmp/inventory.txt
#cat /tmp/inventory3.txt | grep "Disk /dev/sd" > /tmp/inventory.txt

# Inventory drives
DriveCount=0
LastDrive=""
MaxGB=0
if [[ $include -eq 1 ]]; then
	skipdrives=""
fi
while read line
do
	CurrLine=( $line )
	tmp1=${CurrLine[1]}
	tmp2=(${tmp1//\// })
	tmp3=${tmp2[1]}
	tmp4=(${tmp3//:/})
	CurrDisk=${tmp4[0]}
	if [[ "${CurrDisk:0:2}" != "md" ]] && [[ "${CurrDisk:0:4}" != "loop" ]] && [[ "${CurrDisk:0:2}" != "fd" ]]; then
		DiskID[$DriveCount]=$CurrDisk
		if [[ $include -eq 1 ]]; then
			if [[ $includedrives == *"$CurrDisk"* ]]; then
				# Spin up drive in the background
				dd if=/dev/$CurrDisk of=/dev/null count=1 skip=$RandomSector iflag=direct > /dev/null 2> /dev/null &
			else
				skipdrives="$skipdrives,$CurrDisk"
			fi
		fi
		alldrives="$alldrives|$CurrDisk"
		#Bytes=${CurrLine[4]}
		#Bytes=$(echo $line | awk '{print $5}')
		Bytes=$(grep "/dev/$CurrDisk:" < /tmp/inventory.txt | awk '{print $5}')
		DriveBytes[$DriveCount]=$Bytes
		Sectors=$(awk -v bytes="$Bytes" 'BEGIN {printf "%.0f", bytes / 512}')
		DiskSectors[$DriveCount]=$Sectors
		toosmall=1
		if [[ $Bytes -ge 26843545600 ]]; then
			toosmall=0
		fi
		if [[ $Bytes -ge 1048576 ]]; then
			tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1048576}')
			tmp2="MB"
		fi
		if [[ $Bytes -ge 1073741824 ]]; then
			tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1073741824}')
			tmp3=$(awk -v value="$Bytes" 'BEGIN {printf "%0.0f", value / 1073741824}')
			tmp2="GB"
		fi
		if [[ $Bytes -ge 1099511627776 ]]; then
			tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1099511627776}')
			tmp3=$(awk -v value="$Bytes" 'BEGIN {printf "%0.0f", value / 1073741824}')
			tmp2="TB"
		fi


		# Identify if the current disk has been mounted and look for UNRAID files if so
		tmp4=$(mount -l | grep ${DiskID[$DriveCount]})
		MountPoint=""
		if [ "$tmp4" != "" ];then
			mount=( $tmp4 )
			MountPoint=${mount[2]}
			if [ -e "$MountPoint/bzimage" ] || [ -e "$MountPoint/config/ident.cfg" ];then
				MountPoint="bzimage"
				skipdrives="$skipdrives,${DiskID[$DriveCount]}"
				unraid="$unraid,${DiskID[$DriveCount]}"
			fi
		fi
		if [ "$MountPoint" == "bzimage" ];then
			skipdrives="$skipdrives,${DiskID[$DriveCount]}"
			unraid="$unraid,${DiskID[$DriveCount]}"
		else
			if [ "$toosmall" == "1" ];then
				skipdrives="$skipdrives,${DiskID[$DriveCount]}"
				smalldrive="$smalldrive,${DiskID[$DriveCount]}"
			else
				DiskGB[$DriveCount]=$tmp3
				ArrayLoc[$DriveCount]=""
				DiskAvg[$DriveCount]=""
				let DriveCount++
			fi
		fi
	fi
done < /tmp/inventory.txt
if [ -e "/tmp/diskspeed_driveinfo.txt" ];then
	rm /tmp/diskspeed_driveinfo.txt
fi
samples2=$((samples - 1))
CurrDiskID=0
disktested=0

if [[ $include -eq 1 ]]; then
	skipdrives=${skipdrives#","}
fi

function GetUNRAIDSlot
{
	UNRAIDSlot=""
	for (( d=0; d <= $UNRAIDDrives; d++ ))
	do
		if [[ $1 == ${Disk_device[d]} ]]; then
			tmp2=${Disk_name[d]}
			tmp3=${tmp2:4}
			tmp4=${tmp2:5}
			if [[ ${tmp2:0:1} == "d" ]]; then
				UNRAIDSlot="Disk $tmp3"
			fi
			if [[ ${tmp2:0:1} == "c" ]]; then
				if [[ "$tmp4" == "" ]]; then
					UNRAIDSlot="Cache"
				else
					UNRAIDSlot="Cache $tmp4"
				fi
			fi
			if [[ $tmp2 == "parity" ]]; then
				UNRAIDSlot="Parity"
			fi
			if [[ $tmp2 == "parity2" ]]; then
				UNRAIDSlot="Parity 2"
			fi
		fi
	done
}

CurrDiskID=0
for CurrDisk in ${DiskID[@]}
do
	# Mark current disk's location in the RAID array if assigned
	tmp=$(cat /tmp/mdstat | grep rdevName | grep $CurrDisk)
	UNRAIDSlot=""

	if [[ ${#tmp} -gt 0 ]]; then
		i1=$(expr index "$tmp" ".")
		i2=$(expr index "$tmp" "=")
		let i2--
		i3=$(($i2 - $i1))
		UNRAIDSlotNum=${tmp:$i1:i3}
		ArrayLoc[$CurrDiskID]=$UNRAIDSlotNum
	fi

	GetUNRAIDSlot $CurrDisk
	
	if [[ "$UNRAIDSlot" == "" ]]; then
		UNRAIDSlot2=""
	else
		UNRAIDSlot2=" ($UNRAIDSlot)"
	fi
	
	if [[ $log -eq 1 ]]; then
		echo "Current Unraid slot: $UNRAIDSlot - /dev/$CurrDisk" >> diskspeed.log
	fi

	# Get drive information
	if [ -e "/tmp/diskspeed.err" ];then
		rm /tmp/diskspeed.err
	fi
	# fdisk reports the size of all detected drives, including NVMe devices for
	# which hdparm may return no ATA device-capacity information.
	Bytes=${DriveBytes[$CurrDiskID]}
	if ! [[ $Bytes =~ ^[0-9]+$ ]] || [[ $Bytes -le 0 ]]; then
		echo "Error: Unable to determine the size of /dev/$CurrDisk" >&2
		exit 1
	fi
	MB=$((Bytes / 1048576))             # dd's bs=1M uses MiB
	Capacity=$(awk -v bytes="$Bytes" 'BEGIN {printf "%.0f", bytes / 1000000000}')
	GB=$Capacity
	DiskSize[$CurrDiskID]=$(awk -v bytes="$Bytes" 'BEGIN {
		if (bytes >= 1000000000000) printf "%.1f TB", bytes / 1000000000000
		else printf "%.0f GB", bytes / 1000000000
	}')
	hdparm -I /dev/$CurrDisk > /tmp/diskspeed.tmp 2> /tmp/diskspeed.err

	Err=$(grep "failed" /tmp/diskspeed.err)
	if [[ "$Err" != "" ]]; then
		Model=""
		Serial=""
		Bytes=${DriveBytes[$CurrDiskID]}
		# Keep fdisk-derived decimal capacity for NVMe/failed hdparm.
		if [[ $Bytes -ge 1048576 ]]; then
			tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1048576}')
			tmp2="MB"
		fi
		if [[ $Bytes -ge 1073741824 ]]; then
			tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1073741824}')
			tmp3=$(awk -v value="$Bytes" 'BEGIN {printf "%0.0f", value / 1073741824}')
			tmp2="GB"
		fi
		if [[ $Bytes -ge 1099511627776 ]]; then
			tmp=$(awk -v value="$Bytes" 'BEGIN {printf "%0.1f", value / 1099511627776}')
			tmp3=$(awk -v value="$Bytes" 'BEGIN {printf "%0.0f", value / 1073741824}')
			tmp2="TB"
		fi
		if [[ "${tmp:(-2)}" == ".0" ]]; then
			tmp=${tmp::-2}
		fi
		DiskSize[$CurrDiskID]="$tmp $tmp2"
	else
		if [[ $log -eq 1 ]]; then
			echo "/tmp/diskspeed.tmp" >> diskspeed.log
			echo "==========" >> diskspeed.log
			cat /tmp/diskspeed.tmp >> diskspeed.log
			echo "==========" >> diskspeed.log
		fi
		Model=$(grep "Model Number:" /tmp/diskspeed.tmp)
		Serial=$(grep "Serial Number:" /tmp/diskspeed.tmp)
		grep "device size with M = 1000" /tmp/diskspeed.tmp > /tmp/diskspeed2.tmp
		#echo "$CurrDisk";cat /tmp/diskspeed2.tmp;echo "======="
		cut -f2 -d \( /tmp/diskspeed2.tmp > /tmp/diskspeed3.tmp
		cut -f1 -d \) /tmp/diskspeed3.tmp > /tmp/diskspeed4.tmp
		cut -f1 -d " " /tmp/diskspeed4.tmp > /tmp/diskspeed5.tmp
		cut -f2 -d " " /tmp/diskspeed4.tmp > /tmp/diskspeed6.tmp
		
		# hdparm's capacity text is optional. Never replace the fdisk fallback
		# with an empty/non-numeric value (common for NVMe drives).
		ParsedCapacity=$(cat /tmp/diskspeed5.tmp)
		CapacityScale=$(cat /tmp/diskspeed6.tmp)
		if [[ $ParsedCapacity =~ ^[0-9]+$ ]]; then
			if [[ $CapacityScale == "GB" ]]; then
				Capacity=$ParsedCapacity
				if [[ $Capacity -gt 999 ]]; then
					DiskSize[$CurrDiskID]=$(awk -v cap="$Capacity" 'BEGIN {printf "%.1f TB", cap / 1000}')
				else
					DiskSize[$CurrDiskID]="$Capacity GB"
				fi
			elif [[ $CapacityScale == "TB" ]]; then
				Capacity=$((ParsedCapacity * 1000))
				DiskSize[$CurrDiskID]="$ParsedCapacity TB"
			fi
		fi
		rm /tmp/diskspeed.tmp
		rm /tmp/diskspeed2.tmp
		rm /tmp/diskspeed3.tmp
		rm /tmp/diskspeed4.tmp
		rm /tmp/diskspeed5.tmp
		rm /tmp/diskspeed6.tmp
		Model=${Model:21}
		Serial=${Serial:21}
		set -- $Model
		Model=$*
		set -- $Serial
		Serial=$*
	fi

	#for (( d=0; d <= $UNRAIDDrives; d++ ))
	#do
	#	if [[ "$CurrDisk" == "${Disk_name[d]}" ]]; then
	#		DiskSize[$CurrDiskID]=${Disk_capacity[d]}
	#	fi
	#done
	
	if [[ "$Model" == "" ]] && [[ "$Serial" == "" ]]; then
		# Unable to get drive Model, try alternates
		Serial=""
		tmp=$(cat /proc/mdstat | grep "diskId.$UNRAIDSlotNum=")
		if [[ $UNRAIDSlotNum -gt 9 ]]; then
			Model="${tmp:10}"
		else
			Model="${tmp:9}"
		fi
		if [[ "$Model" == "" ]]; then
			DriveID[$CurrDiskID]=$Model
			for (( d=0; d <= $UNRAIDDrives; d++ ))
			do
				if [[ "${Disk_device[d]}" == "$CurrDisk" ]]; then
					DriveID[$CurrDiskID]=${Disk_id[d]}
					break
				fi
			done
		fi
	else
		DriveID[$CurrDiskID]="$Model $Serial"
	fi
	if [[ "${DriveID[$CurrDiskID]}" == "" ]]; then
		DriveID[$CurrDiskID]="Unable to determine"
	fi

	if [[ $log -eq 1 ]]; then
		echo "Model: [$Model]" >> diskspeed.log
		echo "Serial: [$Serial]" >> diskspeed.log
		echo "GB: [$GB]" >> diskspeed.log
	fi

	skip1=$(echo "$skipdrives" | grep $CurrDisk)
	skip2=$(echo "$unraid" | grep $CurrDisk)
	skip3=$(echo "$smalldrive" | grep $CurrDisk)
	
	if [[ "$skip1$skip2$skip3" != "" ]]; then
		if [[ $log -eq 1 ]]; then
			echo "Drive skipped" >> diskspeed.log
		fi
		if [[ "$skip2" != "" ]]; then
			echo -e "$CurUp/dev/$CurrDisk: Skipped (boot or flash drive)\033[K"
		else
			if [[ "$skip3" != "" ]]; then
				echo -e "$CurUp/dev/$CurrDisk$UNRAIDSlot2: Skipped (under 25GB)\033[K"
			else
				echo -e "$CurUp/dev/$CurrDisk$UNRAIDSlot2: Skipped\033[K"
			fi
		fi
		echo
		if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
			rm /tmp/diskspeed.include.$CurrDisk.txt
		fi
	else
		echo -n "Y" > /tmp/diskspeed.include.$CurrDisk.txt
		LoopEnd=$(( $samples - 1 ))
		SlicePer=$(awk -v count="$samples2" 'BEGIN {printf "%.1f", 100 / count}')
		for (( CurrSample=0; CurrSample <=$LoopEnd; CurrSample++ ))
		do
			# Compute the GB offset & displayed offset
			if [[ $CurrSample -eq 0 ]];then
				startpos=0
				startposdisp=0
				CurrPer=0
			elif [[ $CurrSample -eq $LoopEnd ]];then
				if [[ $fast -eq 1 ]]; then
					startpos=$((MB - 201))  # Leave room for the full 200 MiB read
				else
					startpos=$(( Capacity - 2 ))
				fi
				startposdisp=$(awk -v cap="$Capacity" 'BEGIN {printf "%.0f", cap}')
				CurrPer=100
			else
				CurrPer=$(awk -v per="$CurrPer" -v slice="$SlicePer" 'BEGIN {print per + slice}')
				CurrPer2=$(awk -v per="$CurrPer" 'BEGIN {print per * 0.01}')
				if [[ $fast -eq 1 ]]; then
					startpos=$(awk -v mb="$MB" -v frac="$CurrPer2" 'BEGIN {printf "%.0f", mb * frac}')
					startposdisp=$(awk -v cap="$Capacity" -v frac="$CurrPer2" 'BEGIN {printf "%.0f", cap * frac}')
				else
					startpos=$(awk -v cap="$Capacity" -v frac="$CurrPer2" 'BEGIN {printf "%.0f", cap * frac}')
					startposdisp=$(awk -v cap="$Capacity" -v frac="$CurrPer2" 'BEGIN {printf "%.0f", cap * frac}')
				fi
			fi

			if (( startpos < 0 )); then
				echo "Error: Negative test offset for /dev/$CurrDisk" >&2
				exit 1
			fi
			if [[ $log -eq 1 ]]; then
				echo "startpos: [$startpos]" >> diskspeed.log
				echo "startposdisp: [$startposdisp]" >> diskspeed.log
				echo "CurrPer: [$CurrPer]" >> diskspeed.log
			fi
			IterationTotal=0
			disktested=1
			for (( iter=1; iter <= $iterations; iter++ ))
			do
				startposdispsize="GB"
				startposdispnum=$startposdisp
				if [[ $startposdisp -gt 999 ]];then
					startposdispnum=$(awk -v pos="$startposdisp" 'BEGIN {printf "%.1f", pos / 1000}')
					if [[ "${startposdispnum:(-2)}" == ".0" ]]; then
						startposdispnum=${startposdispnum::-2}
					fi
					startposdispsize="TB"
				fi
				if [[ $iterations -eq 1 ]];then
					echo -e -n "$CurUp"
					echo -e "Performance testing /dev/$CurrDisk$UNRAIDSlot2 at $startposdispnum $startposdispsize ($CurrPer%)\033[K"
					if [[ $log -eq 1 ]]; then
						echo "Performance testing /dev/$CurrDisk$UNRAIDSlot2 at $startposdispnum $startposdispsize ($CurrPer%)  $startpos" >> diskspeed.log
					fi
				else
				echo -e -n "$CurUp"
				echo -e "Performance testing /dev/$CurrDisk$UNRAIDSlot2 at $startposdispnum $startposdispsize ($CurrPer%), pass $iter of $iterations\033[K"
					if [[ $log -eq 1 ]]; then
						echo "Performance testing /dev/$CurrDisk$UNRAIDSlot2 at $startposdispnum $startposdispsize ($CurrPer%), pass $iter of $iterations $startpos" >> diskspeed.log
					fi
				fi
				if [[ $fast -eq 1 ]]; then
					# For the fash test, position the drive head at the start point, does help raise speed rate
					dd if=/dev/$CurrDisk of=/dev/null bs=1M count=1 skip=$startpos iflag=direct 2> /tmp/diskspeed_results.txt
					dd if=/dev/$CurrDisk of=/dev/null bs=1M count=200 skip=$startpos iflag=direct 2> /tmp/diskspeed_results.txt
					if [[ $log -eq 1 ]]; then
						echo "dd if=/dev/$CurrDisk of=/dev/null bs=1M count=200 skip=$startpos iflag=direct" >> diskspeed.log
					fi
				else
					dd if=/dev/$CurrDisk of=/dev/null bs=1GB count=1 skip=$startpos iflag=direct 2> /tmp/diskspeed_results.txt
					if [[ $log -eq 1 ]]; then
						echo "dd if=/dev/$CurrDisk of=/dev/null bs=1GB count=1 skip=$startpos iflag=direct" >> diskspeed.log
					fi
				fi
				if [[ $log -eq 1 ]]; then
					echo "/tmp/diskspeed_results.txt" >> diskspeed.log
					echo "==========" >> diskspeed.log
					cat /tmp/diskspeed_results.txt >> diskspeed.log
					echo "==========" >> diskspeed.log
				fi
				# GNU dd field positions vary with coreutils versions. The final
				# fields on the copied line are always throughput and its unit.
				read -r speed speed2 < <(awk '/copied/ {v=$(NF-1); u=$NF} END {print v, u}' /tmp/diskspeed_results.txt)
				case "$speed2" in
					kB/s) multiplier=1000 ;;
					MB/s) multiplier=1000000 ;;
					GB/s) multiplier=1000000000 ;;
					B/s)  multiplier=1 ;;
					*) echo "Error: Cannot read dd throughput for /dev/$CurrDisk at $CurrPer%" >&2
					   cat /tmp/diskspeed_results.txt >&2; exit 1 ;;
				esac
				if ! [[ $speed =~ ^[0-9]+([.][0-9]+)?$ ]]; then
					echo "Error: Invalid dd speed '$speed' for /dev/$CurrDisk" >&2
					exit 1
				fi
				ratedspeed=$(awk -v speed="$speed" -v multiplier="$multiplier" 'BEGIN {printf "%.0f", speed * multiplier}')
				if [[ $log -eq 1 ]]; then
					echo "ratedspeed: [$ratedspeed]" >> diskspeed.log
				fi
				IterationLocation[$CurrSample]=$startposdisp
				IterationTotal=$(( $IterationTotal + $ratedspeed ))
			done
			Spot=$(($IterationTotal / $iterations ))
			speedidx[$CurrSample]=$Spot
		done

		# Cleanup old files if the script was aborted during the previous run
		if [ -e "/tmp/diskspeed.$CurrDisk.graph1" ];then
			rm "/tmp/diskspeed.$CurrDisk.graph1"
		fi
		if [ -e "/tmp/diskspeed.$CurrDisk.graph2" ];then
			rm "/tmp/diskspeed.$CurrDisk.graph2"
		fi

		total=0
		for (( CurrSample=0; CurrSample <=$LoopEnd; CurrSample++ ))
		do
			total=$(($total + ${speedidx[$CurrSample]}))
			BytesSec=${speedidx[$CurrSample]}
			#CurrLoc=$((${IterationLocation[$CurrSample]} * 1000000000))
			n=${IterationLocation[$CurrSample]}
			CurrLoc=$(awk -v value="$n" 'BEGIN {printf "%0.0f", value * 1000000000}')
			if [[ $CurrSample -eq 0 ]];then
				CurrPer=0
			elif [[ $CurrSample -eq $LoopEnd ]];then
				CurrPer=100
			else
				CurrPer=$(awk -v per="$CurrPer" -v slice="$SlicePer" 'BEGIN {print per + slice}')
			fi
			if [[ $CurrSample -ne $LoopEnd ]];then
				echo -n "[$CurrPer,$BytesSec]," >> /tmp/diskspeed.$CurrDisk.graph1
				echo -n "[$CurrLoc,$BytesSec]," >> /tmp/diskspeed.$CurrDisk.graph2
			else
				echo -n "[$CurrPer,$BytesSec]" >> /tmp/diskspeed.$CurrDisk.graph1
				echo -n "[$CurrLoc,$BytesSec]" >> /tmp/diskspeed.$CurrDisk.graph2
			fi
		done

		diskavgspeed=$(($total / $samples / 1000000))
		DiskAvg[$CurrDiskID]=$diskavgspeed
		echo -e "$CurUp/dev/$CurrDisk$UNRAIDSlot2: $diskavgspeed MB/sec avg\033[K"
		echo
		if [[ $log -eq 1 ]]; then
			echo "/dev/$CurrDisk$UNRAIDSlot2: $diskavgspeed MB/sec avg" >> diskspeed.log
			echo "========== END OF DRIVE ==========" >> diskspeed.log
		fi
	fi

	let CurrDiskID++
done

if [[ $disktested -eq 0 ]];then
	echo "All drives were excluded, nothing to report."
	if [[ $log -eq 1 ]]; then
		echo "All drives exluded" >> diskspeed.log
	fi
	exit 1
fi

if [[ $log -eq 1 ]]; then
	echo "Program complete" >> diskspeed.log
fi


# Generate the report
echo -e -n "<!DOCTYPE html><html><head><meta http-equiv=\042content-type\042 content=\042text/html; charset=UTF-8\042><title>Disk Speed Test</title><script type=\042text/javascript\042 src=\042http://code.jquery.com/jquery-1.9.1.js\042></script><script type=\042text/javascript\042>" > "$outputfile"
echo -e "\044(function () {\044('#graph1').highcharts({title:{text:'Disk Speed Test'},subtitle:{text:'By Position Percentile'},xAxis:{min:0,max:100,labels:{formatter:function\050\051{return this.value+'%';}}},yAxis:{min:0,title:{text:'Speed/Sec'}},tooltip:{formatter:function(){return this.series.name+': '+this.y/1000000+'MB/sec at '+this.x+'%';}},legend:{enabled:true},plotOptions:{series:{marker:{enabled:false},animation:false,connectNulls:true}},series: [" >> "$outputfile"

# Generate graph lines for drives in the array
DisksProcessed=0
for (( slot=0; slot < 99; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
			if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
				GetUNRAIDSlot $CurrDisk
				drivenum=$UNRAIDSlot

				data=$(<"/tmp/diskspeed.$CurrDisk.graph1")
				rm /tmp/diskspeed.$CurrDisk.graph1
				echo "{name:'$drivenum',data:[$data]}" >> "$outputfile"
				let DisksProcessed++
				if [[ $DisksProcessed -lt $DriveCount ]];then
					echo "," >> "$outputfile"
				fi
			fi
		fi
		let CurrDiskID++
	done
done
# Generate graph lines for drives outside of the array
CurrDiskID=0
for CurrDisk in ${DiskID[@]}
do
	if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
		if [ "${ArrayLoc[$CurrDiskID]}" == "" ];then
			data=$(<"/tmp/diskspeed.$CurrDisk.graph1")
			rm /tmp/diskspeed.$CurrDisk.graph1
			DiskName=$CurrDisk
			GetUNRAIDSlot $CurrDisk
			if [[ $UNRAIDSlot != "" ]]; then
				DiskName=$UNRAIDSlot
			fi
			echo "{name:'$DiskName',data:[$data]}" >> "$outputfile"
			let DisksProcessed++
			if [[ $DisksProcessed -lt $DriveCount ]];then
				echo "," >> "$outputfile"
			fi
		fi
	fi
	let CurrDiskID++
done

echo -e -n "]});});\044(function () {\044('#graph2').highcharts({title:{text:'Disk Speed Test'},subtitle:{text:'By Drive Size'},xAxis:{min:0},yAxis:{min:0,title:{text:'Speed/Sec'}},tooltip:{formatter:function(){return this.series.name+': '+this.y/1000000+'MB/sec at '+this.x/1000000000+'GB';}},legend:{enabled:true},plotOptions:{series:{marker:{enabled:false},animation:false,connectNulls:true}},series: [" >> "$outputfile"

# Generate graph lines for Parity 1
DisksProcessed=0
for (( slot=0; slot < 99; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		GetUNRAIDSlot $CurrDisk
		if [[ $UNRAIDSlot == "Parity" ]]; then
			if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
				if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
					drivenum=$UNRAIDSlot
					data=$(<"/tmp/diskspeed.$CurrDisk.graph2")
					rm /tmp/diskspeed.$CurrDisk.graph2
					echo "{name:'$drivenum',data:[$data]}" >> "$outputfile"
					let DisksProcessed++
					if [[ $DisksProcessed -lt $DriveCount ]];then
						echo "," >> "$outputfile"
					fi
				fi
			fi
		fi
		let CurrDiskID++
	done
done
# Generate graph lines for Pairty 2
DisksProcessed=0
for (( slot=0; slot < 99; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		GetUNRAIDSlot $CurrDisk
		if [[ $UNRAIDSlot == "Parity 2" ]]; then
			if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
				if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
					drivenum=$UNRAIDSlot
					data=$(<"/tmp/diskspeed.$CurrDisk.graph2")
					rm /tmp/diskspeed.$CurrDisk.graph2
					echo "{name:'$drivenum',data:[$data]}" >> "$outputfile"
					let DisksProcessed++
					if [[ $DisksProcessed -lt $DriveCount ]];then
						echo "," >> "$outputfile"
					fi
				fi
			fi
		fi
		let CurrDiskID++
	done
done
# Generate graph lines for array drives
DisksProcessed=0
for (( slot=0; slot < 99; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		GetUNRAIDSlot $CurrDisk
		if [[ $UNRAIDSlot != "Parity" ]] && [[ $UNRAIDSlot != "Parity 2" ]]; then
			if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
				if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
					drivenum=$UNRAIDSlot
					data=$(<"/tmp/diskspeed.$CurrDisk.graph2")
					rm /tmp/diskspeed.$CurrDisk.graph2
					echo "{name:'$drivenum',data:[$data]}" >> "$outputfile"
					let DisksProcessed++
					if [[ $DisksProcessed -lt $DriveCount ]];then
						echo "," >> "$outputfile"
					fi
				fi
			fi
		fi
		let CurrDiskID++
	done
done






# Generate graph lines for drives outside of the array
na="<font color=grey>n/a</font>"
for (( slot=1; slot <= 99; slot++ ))
do
	CurrDiskID=0
	if [[ $slot -eq 1 ]]; then
		MatchID="Cache"
	else
		MatchID="Cache $slot"
	fi
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		GetUNRAIDSlot $CurrDisk
		if [[ $UNRAIDSlot == $MatchID ]]; then
			if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
				if [ "${ArrayLoc[$CurrDiskID]}" == "" ];then
					data=$(<"/tmp/diskspeed.$CurrDisk.graph2")
					rm /tmp/diskspeed.$CurrDisk.graph2
					DiskName=$CurrDisk
					if [[ $UNRAIDSlot != "" ]]; then
						DiskName=$UNRAIDSlot
					fi
					echo "{name:'$DiskName',data:[$data]}" >> "$outputfile"
					let DisksProcessed++
					if [[ $DisksProcessed -lt $DriveCount ]];then
						echo "," >> "$outputfile"
					fi
				fi
			fi
		fi
		let CurrDiskID++
	done
done
for CurrDisk in ${DiskID[@]}
do
	GetUNRAIDSlot $CurrDisk
	if [[ $UNRAIDSlot == "" ]]; then
		if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
			if [ "${ArrayLoc[$CurrDiskID]}" == "" ];then
				data=$(<"/tmp/diskspeed.$CurrDisk.graph2")
				rm /tmp/diskspeed.$CurrDisk.graph2
				DiskName=$CurrDisk
				if [[ $UNRAIDSlot != "" ]]; then
					DiskName=$UNRAIDSlot
				fi
				echo "{name:'$DiskName',data:[$data]}" >> "$outputfile"
				let DisksProcessed++
				if [[ $DisksProcessed -lt $DriveCount ]];then
					echo "," >> "$outputfile"
				fi
			fi
		fi
	fi
	let CurrDiskID++
done



echo -e -n "]});});</script></head><body><style type=\042text/css\042>body,td {font-family:Arial,Helvetica,sans-serif;font-size:13px;color:black;}</style><script src=\042http://code.highcharts.com/highcharts.js\042></script><script src=\042http://code.highcharts.com/modules/exporting.js\042></script><div align=\042center\042><table border=0 cellpadding=0 cellspacing=0><tr><td><div id=\042graph1\042 style=\042min-width: 310px; width: 1000px; height: 400px; margin: 0 auto;" >> "$outputfile"
if [[ $ShowGraph1 -eq 0 ]]; then
	echo -n "display:none" >> "$outputfile"
fi
echo -e "\042></div><div id=\042graph2\042 style=\042min-width: 310px; width: 1000px; height: 400px; margin: 0 auto\042></div>" >> "$outputfile"

echo "<b>Drive Identification</b><br><table border=0 cellpadding=0 cellspacing=0>" >> "$outputfile"

# Generate disk information for Parity 1
for (( slot=0; slot < 99; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		GetUNRAIDSlot $CurrDisk
		if [[ $UNRAIDSlot == "Parity" ]]; then
			if [[ "${DiskAvg[$CurrDiskID]}" == "" ]]; then
				CurrDiskAvg=$na
			else
				CurrDiskAvg="${DiskAvg[$CurrDiskID]}&nbsp;MB/sec&nbsp;avg"
			fi
			DiskName=$UNRAIDSlot
			if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
				echo "<tr><td>$DiskName:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
			fi
		fi
		let CurrDiskID++
	done
done
# Generate disk information for Parity 2
for (( slot=0; slot < 99; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		GetUNRAIDSlot $CurrDisk
		if [[ $UNRAIDSlot == "Parity 2" ]]; then
			if [[ "${DiskAvg[$CurrDiskID]}" == "" ]]; then
				CurrDiskAvg=$na
			else
				CurrDiskAvg="${DiskAvg[$CurrDiskID]}&nbsp;MB/sec&nbsp;avg"
			fi
			DiskName=$UNRAIDSlot
			if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
				echo "<tr><td>$DiskName:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
			fi
		fi
		let CurrDiskID++
	done
done
# Generate disk information for array drives
for (( slot=0; slot < 99; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		GetUNRAIDSlot $CurrDisk
		if [[ $UNRAIDSlot != "Parity" ]] && [[ $UNRAIDSlot != "Parity 2" ]]; then
			if [[ "${DiskAvg[$CurrDiskID]}" == "" ]]; then
				CurrDiskAvg=$na
			else
				CurrDiskAvg="${DiskAvg[$CurrDiskID]}&nbsp;MB/sec&nbsp;avg"
			fi
			DiskName=$UNRAIDSlot
			if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
				echo "<tr><td>$DiskName:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
			fi
		fi
		let CurrDiskID++
	done
done

# Generate disk information for cache drives
for (( slot=1; slot <= 99; slot++ ))
do
	CurrDiskID=0
	if [[ $slot -eq 1 ]]; then
		MatchID="Cache"
	else
		MatchID="Cache $slot"
	fi
	for CurrDisk in ${DiskID[@]}
	do
		if [[ "${DiskAvg[$CurrDiskID]}" == "" ]]; then
			CurrDiskAvg=$na
		else
			CurrDiskAvg="${DiskAvg[$CurrDiskID]}&nbsp;MB/sec&nbsp;avg"
		fi
		GetUNRAIDSlot $CurrDisk
		if [[ $MatchID == $UNRAIDSlot ]]; then
			echo "<tr><td>$UNRAIDSlot:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
			break
		fi
		let CurrDiskID++
	done
done

# Generate disk information for out of array drives
CurrDiskID=0
for CurrDisk in ${DiskID[@]}
do
	if [[ "${DiskAvg[$CurrDiskID]}" == "" ]]; then
		CurrDiskAvg=$na
	else
		CurrDiskAvg="${DiskAvg[$CurrDiskID]}&nbsp;MB/sec&nbsp;avg"
	fi
	GetUNRAIDSlot $CurrDisk
	if [[ $UNRAIDSlot == "" ]]; then
		echo "<tr><td>$CurrDisk:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
	fi
	let CurrDiskID++
done


echo "</table><br/>Generated on <b>$HOSTNAME</b> at `date`<br/>" >> "$outputfile"
if [[ $iterations -eq 1 ]]; then
	echo "Drives scanned $iterations time every $SlicePer%" >> "$outputfile"
else
	echo "Drives scanned $iterations times every $SlicePer%" >> "$outputfile"
fi
echo "</td></tr></table></div></body></html>" >> "$outputfile"

echo "To see a graph of the drive's speeds, please browse to the current"
echo "directory and open the file $outputfile in your Internet Browser"
echo "application."
echo

# Cleanup
if [ -e "/tmp/mdstat" ];then
	rm /tmp/mdstat
fi
if [ -e "/tmp/hdparm" ];then
	rm /tmp/hdparm
fi
if [ -e "/tmp/hdparm2" ];then
	rm /tmp/hdparm2
fi
if [ -e "/tmp/diskspeed_results.txt" ];then
	rm /tmp/diskspeed_results.txt
fi
if [ -e "/tmp/inventory1.txt" ];then
	rm /tmp/inventory1.txt
fi
if [ -e "/tmp/inventory2.txt" ];then
	rm /tmp/inventory2.txt
fi
if [ -e "/tmp/inventory.txt" ];then
	rm /tmp/inventory.txt
fi
if [ -e "/tmp/diskspeed.err" ];then
	rm /tmp/diskspeed.err
fi

for CurrDisk in ${DiskID[@]}
do
	if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
		rm /tmp/diskspeed.include.$CurrDisk.txt
	fi
	let CurrDiskID++
done
