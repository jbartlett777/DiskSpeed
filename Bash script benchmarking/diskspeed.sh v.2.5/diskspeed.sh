#!/bin/bash

echo
echo "diskspeed.sh for UNRAID, version 2.4"
echo "By John Bartlett. Support board @ limetech: http://goo.gl/ysJeYV"
echo

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
# external drive cards.
# Added -g --graph option to display the drive by percentage comparison graph
# Added warning if files on the array are open which could mean drives are active
# Added spin up drive support by reading a random spot on the drive
#
# Version 2.3
# Changed to use the "dd" command for speed testing, eliminates risk of hitting
# the end of the drive. The app will read 200MB of data at each testing location.
# Before scanning each spot, uses the "dd" command to place the drive head at the
# start of the test location.
# Added -o --output option for saving the file to a given location/name (credit pkn)
# Added report generation date & server name to the end of the report (credit pkn)
# Added a Y axis floor of zero to keep the graph from display negative ranges
# Hid graph that compared each drive by percentage. If you wish to re-enable it,
# change the line "ShowGraph1=0" to "ShowGraph1=1"
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
	echo "-h, --help:       Displays help/syntax (this)"
	echo "-l, --log:        Create a debug log file named 'diskspeed.log'"
	echo "-f, --fast:       Scan 200MB at each location instead of 1GB. Less accurate."
	echo
	exit 0
fi

# See if the array is in use
lsof 2>/dev/null | grep "/mnt/disk[0-9]*/" > /tmp/lsof.txt
if [[ -s /tmp/lsof.txt ]]; then
	echo "Warning: Files in the array are open. Please refer to /tmp/lsof.txt for a list"
	echo
else
	rm /tmp/lsof.txt
fi

cp /proc/mdcmd /tmp
mdNumDisabled=$(grep "mdNumDisabled=" /tmp/mdcmd)
mdNumInvalid=$(grep "mdNumInvalid=" /tmp/mdcmd)
mdNumMissing=$(grep "mdNumMissing=" /tmp/mdcmd)
sbNumDisks=$(grep "sbNumDisks=" /tmp/mdcmd)
mdResyncPos=$(grep "mdResyncPos=" /tmp/mdcmd)

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

if [[ $mdNumDisabled -ne 0 ]]; then
	# Check to see if there is no parity drive install, allow if not and only one disabled drive
	if [[ $mdNumDisabled -eq 1 ]]; then
		rdevName=$(grep "rdevName.0=" /tmp/mdcmd)
		if [ "$rdevName" != "rdevName.0=" ];then
			echo "Error: There are disabled drives in the array"
			exit 1
		fi
	else
		echo "Error: There are disabled drives in the array"
		exit 1
	fi
fi
if [[ $mdNumInvalid -ne 0 ]];then
	# Check to see if there is no parity drive install, allow if not and only one invalid drive
	if [[ $mdNumInvalid -eq 1 ]]; then
		rdevName=$(grep "rdevName.0=" /tmp/mdcmd)
		if [ "$rdevName" != "rdevName.0=" ];then
			echo "Error: There are invalid drives in the array"
			exit 1
		fi
	else
		echo "Error: There are invalid drives in the array"
		exit 1
	fi
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

fdisk -l > /tmp/inventory1.txt 2> /dev/null
if [[ $log -eq 1 ]]; then
	echo "/tmp/inventory1.txt" >> diskspeed.log
	echo "==========" >> diskspeed.log
	cat /tmp/inventory1.txt >> diskspeed.log
	echo "==========" >> diskspeed.log
fi
grep "Disk /" /tmp/inventory1.txt > /tmp/inventory2.txt
sort /tmp/inventory2.txt -o /tmp/inventory.txt
rm /tmp/inventory2.txt
# Spin up drives in the background
while read line
do
	CurrLine=( $line )
	tmp=${CurrLine[1]}
	CurrDisk=${tmp:5:3}
	Bytes=$(grep "/dev/$CurrDisk" < /tmp/inventory.txt | awk '{print $5}')
	Sectors=$(awk 'BEGIN{printf("%0.0f",'$Bytes' / '512')}')
	Sectors=$(awk 'BEGIN{printf("%0.0f",'$Sectors' / '4')}')
	RandomSector=$(shuf -i 0-$Sectors -n 1)
	dd if=/dev/$CurrDisk of=/dev/null count=1 skip=$RandomSector iflag=direct > /dev/null 2> /dev/null &
done < /tmp/inventory.txt

echo "Syncing disks..."
sync
sync
echo -e -n "\033[1A\033[K"

# Identify cache drive
tmp=$(mount -l | grep /mnt/cache)
if [ "$tmp" == "" ]; then
	CacheID=""
else
	CacheID=${tmp:5:3}
fi

# Inventory drives
DriveCount=0
LastDrive=""
MaxGB=0
while read line
do
	CurrLine=( $line )
	tmp1=${CurrLine[1]}
	tmp2=${tmp1:5:3}
	DiskID[$DriveCount]=$tmp2
	LastDrive=$tmp2
	tmp1=${CurrLine[2]}
	i=$(expr index "$tmp1" ".")
	tmp2=${CurrLine[3]}
	tmp2=${tmp2:0:2}
	if [[ $i -gt 0 ]]; then
		let i--
		tmp3=${tmp1:0:$i}
	else
		tmp3=$tmp1
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
		#echo "Disk /dev/${DiskID[$DriveCount]} skipped; UNRAID boot or flash drive"
		skipdrives="$skipdrives,${DiskID[$DriveCount]}"
		unraid="$unraid,${DiskID[$DriveCount]}"
	else
		if [ "$tmp2" == "MB" ] || [[ $tmp3 -lt 25 ]];then
			#echo "Disk /dev/${DiskID[$DriveCount]} skipped for being under 25 GB"
			skipdrives="$skipdrives,${DiskID[$DriveCount]}"
			smalldrive="$smalldrive,${DiskID[$DriveCount]}"
		else
			DiskGB[$DriveCount]=$tmp3
			if [ "$tmp2" == "GB" ];then
				if [[ $tmp3 -gt 999 ]];then
					tmp3=$(awk 'BEGIN{printf("%0.1f",'$tmp3' / '1000')}')
					tmp2="TB"
				fi
			fi
			DiskSize[$DriveCount]="$tmp3 $tmp2"
			ArrayLoc[$DriveCount]=""
			DiskAvg[$DriveCount]=""
			let DriveCount++
		fi
	fi
done < /tmp/inventory.txt
if [ -e "/tmp/diskspeed_driveinfo.txt" ];then
	rm /tmp/diskspeed_driveinfo.txt
fi

#CursorUp="\033[1A"

samples2=$((samples - 1))
CurrDiskID=0
disktested=0

echo

for CurrDisk in ${DiskID[@]}
do
	# Mark current disk's location in the RAID array if assigned
	tmp=$(cat /tmp/mdcmd | grep rdevName | grep $CurrDisk)
	UNRAIDSlot=""
	#DriveAvg1[$CurrDisk]=0
	#DriveAvg2[$CurrDisk]=0
	#DriveAvg3[$CurrDisk]=0
	#DriveAvg4[$CurrDisk]=0
	#Avg1=0
	#Avg2=0
	#Avg3=0
	#Avg4=0

	if [[ ${#tmp} -gt 0 ]]; then
		i1=$(expr index "$tmp" ".")
		i2=$(expr index "$tmp" "=")
		let i2--
		i3=$(($i2 - $i1))
		UNRAIDSlotNum=${tmp:$i1:i3}
		ArrayLoc[$CurrDiskID]=$UNRAIDSlotNum
		if [[ $UNRAIDSlotNum -eq 0 ]];then
			UNRAIDSlot=" (Parity)"
		else
			UNRAIDSlot=" (Disk $UNRAIDSlotNum)"
		fi
	fi
	if [ "$CurrDisk" == "$CacheID" ];then
		UNRAIDSlot=" (Cache)"
	fi
	if [[ $log -eq 1 ]]; then
		echo "Current Unraid slot: $UNRAIDSlot - /dev/$CurrDisk" >> diskspeed.log
	fi

	# Get drive information
	hdparm -I /dev/$CurrDisk > /tmp/diskspeed.tmp 2> /dev/null
	if [[ $log -eq 1 ]]; then
		echo "/tmp/diskspeed.tmp" >> diskspeed.log
		echo "==========" >> diskspeed.log
		cat /tmp/diskspeed.tmp >> diskspeed.log
		echo "==========" >> diskspeed.log
	fi
	Model=$(grep "Model Number:" /tmp/diskspeed.tmp)
	Serial=$(grep "Serial Number:" /tmp/diskspeed.tmp)
	if [[ $fast -eq 1 ]]; then
		Bytes=$(grep "/dev/$CurrDisk" < /tmp/inventory.txt | awk '{print $5}')
		GB=$(awk 'BEGIN{printf("%0.0f",'$Bytes' / '1024')}')
		GB=$(awk 'BEGIN{printf("%0.0f",'$GB' / '1024')}')
		GB=$(awk 'BEGIN{printf("%0.0f",'$GB')}')
	else
		GB=$(grep "device size with M = 1024" /tmp/diskspeed.tmp)
		GB=${GB:32}
		GB=${GB/" MBytes"/""}
		GB=$(($GB / 1024))
	fi
	rm /tmp/diskspeed.tmp
	Model=${Model:21}
	Serial=${Serial:21}
	set -- $Model
	Model=$*
	set -- $Serial
	Serial=$*
	if [[ "$Model" == "" ]]; then
		# Unable to get drive Model, fetch it from UNRAID
		Serial=""
		tmp=$(cat /proc/mdcmd | grep "diskId.$UNRAIDSlotNum=")
		if [[ $UNRAIDSlotNum -gt 9 ]]; then
			Model="Moo ${tmp:10}"
		else
			Model="Moo ${tmp:9}"
		fi
		DriveID[$CurrDiskID]=$Model
	else
		DriveID[$CurrDiskID]="$Model $Serial"
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
			echo -e "\033[1A/dev/$CurrDisk: Skipped (boot or flash drive)\033[K"
		else
			if [[ "$skip3" != "" ]]; then
				echo -e "\033[1A/dev/$CurrDisk$UNRAIDSlot: Skipped (under 25GB)\033[K"
			else
				echo -e "\033[1A/dev/$CurrDisk$UNRAIDSlot: Skipped\033[K"
			fi
		fi
		echo
		if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
			rm /tmp/diskspeed.include.$CurrDisk.txt
		fi
	else
		echo -n "Y" > /tmp/diskspeed.include.$CurrDisk.txt
		LoopEnd=$(( $samples - 1 ))
		SlicePer=$(awk 'BEGIN{printf("%0.0f",'100' / '$samples2')}')
		for (( CurrSample=0; CurrSample <=$LoopEnd; CurrSample++ ))
		do
			# Compute the GB offset & displayed offset
			if [[ $CurrSample -eq 0 ]];then
				startpos=0
				startposdisp=0
				CurrPer=0
			elif [[ $CurrSample -eq $LoopEnd ]];then
				if [[ $fast -eq 1 ]]; then
					startpos=$(($GB - 201))
				else
					startpos=$(($GB - 2))
				fi
				startposdisp=${DiskGB[$CurrDiskID]}
				CurrPer=100
			else
				CurrPer=$(( $CurrPer + $SlicePer ))
				tmp=${DiskGB[$CurrDiskID]}
				if [[ $CurrPer -lt 10 ]]; then
					startpos=$(awk 'BEGIN{printf("%0.0f",'$GB' * '0.0$CurrPer')}')
					startposdisp=$(awk 'BEGIN{printf("%0.0f",'$tmp' * '0.0$CurrPer')}')
				else
					startpos=$(awk 'BEGIN{printf("%0.0f",'$GB' * '0.$CurrPer')}')
					startposdisp=$(awk 'BEGIN{printf("%0.0f",'$tmp' * '0.$CurrPer')}')
				fi
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
					startposdispnum=$(awk 'BEGIN{printf("%0.2f",'$startposdisp' / '1000')}')
					startposdispsize="TB"
				fi
				if [[ $iterations -eq 1 ]];then
					echo -e "\033[1APerformance testing /dev/$CurrDisk$UNRAIDSlot at $startposdispnum $startposdispsize ($CurrPer%)\033[K"
					if [[ $log -eq 1 ]]; then
						echo "Performance testing /dev/$CurrDisk$UNRAIDSlot at $startposdispnum $startposdispsize ($CurrPer%)" >> diskspeed.log
					fi
				else
					echo -e "\033[1APerformance testing /dev/$CurrDisk$UNRAIDSlot at $startposdispnum $startposdispsize ($CurrPer%), pass $iter of $iterations\033[K"
					if [[ $log -eq 1 ]]; then
						echo "Performance testing /dev/$CurrDisk$UNRAIDSlot at $startposdispnum $startposdispsize ($CurrPer%), pass $iter of $iterations" >> diskspeed.log
					fi
				fi
				# Position drive head
				startpos2=$(( $startpos - 1 ))
				if [[ $startpos2 -lt 0 ]]; then
					startpos2=0
				fi
				if [[ $fast -eq 1 ]]; then
					dd if=/dev/$CurrDisk of=/dev/null bs=1M count=1 skip=$startpos2 iflag=direct 2> /dev/null
					dd if=/dev/$CurrDisk of=/dev/null bs=1M count=200 skip=$startpos iflag=direct 2> /tmp/diskspeed_results.txt
					echo "dd if=/dev/$CurrDisk of=/dev/null bs=1M count=200 skip=$startpos iflag=direct" >> diskspeed.log
				else
					dd if=/dev/$CurrDisk of=/dev/null bs=1GB count=1 skip=$startpos iflag=direct 2> /tmp/diskspeed_results.txt
					echo "dd if=/dev/$CurrDisk of=/dev/null bs=1GB count=1 skip=$startpos iflag=direct" >> diskspeed.log
				fi
				if [[ $log -eq 1 ]]; then
					echo "/tmp/diskspeed_results.txt" >> diskspeed.log
					echo "==========" >> diskspeed.log
					cat /tmp/diskspeed_results.txt >> diskspeed.log
					echo "==========" >> diskspeed.log
				fi
				#echo "dd if=/dev/$CurrDisk of=/dev/null bs=1M count=200 skip=$startpos iflag=direct"
				#cat /tmp/diskspeed_results.txt
				#echo
				speed=$(grep copied < /tmp/diskspeed_results.txt | awk '{print $8}')
				speed2=$(grep copied < /tmp/diskspeed_results.txt | awk '{print $9}')
				if [ "$speed2" == "kB/s" ];then
					ratedspeed=$(awk 'BEGIN{printf("%.0f",'$speed' * '1000')}')
				fi
				if [ "$speed2" == "MB/s" ];then
					ratedspeed=$(awk 'BEGIN{printf("%.0f",'$speed' * '1000000')}')
				fi
				if [ "$speed2" == "GB/s" ];then
					ratedspeed=$(awk 'BEGIN{printf("%.0f",'$speed' * '1000000000')}')
				fi
				if [[ $log -eq 1 ]]; then
					echo "ratedspeed: [$ratedspeed]" >> diskspeed.log
				fi

				IterationLocation[$CurrSample]=$startposdisp
				IterationTotal=$(( $IterationTotal + $ratedspeed ))
			done
			Spot=$(($IterationTotal / $iterations ))
			speedidx[$CurrSample]=$Spot
			#if [[ $CurrPer -lt 26 ]]; then
			#	Avg1=$(( $Avg1 + $Spot ))
			#fi
			#if [[ $CurrPer -gt 25 && $CurrPer -lt 51 ]]; then
			#	Avg2=$(( $Avg2 + $Spot ))
			#fi
			#if [[ $CurrPer -gt 50 && $CurrPer -lt 76 ]]; then
			#	Avg3=$(( $Avg3 + $Spot ))
			#fi
			#if [[ $CurrPer -gt 75 ]]; then
			#	Avg4=$(( $Avg4 + $Spot ))
			#fi
		done
		#Avg1=$(( $Avg1 / $iterations ))
		#Avg2=$(( $Avg2 / $iterations ))
		#Avg3=$(( $Avg3 / $iterations ))
		#Avg4=$(( $Avg4 / $iterations ))
		#DriveAvg1[$CurrDisk]=$Avg1
		#DriveAvg2[$CurrDisk]=$Avg2
		#DriveAvg3[$CurrDisk]=$Avg3
		#DriveAvg4[$CurrDisk]=$Avg4

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
			#BytesSec=$((${speedidx[$CurrSample]} * 1000))
			BytesSec=${speedidx[$CurrSample]}
			CurrLoc=$((${IterationLocation[$CurrSample]} * 1000000000))
			if [[ $CurrSample -eq 0 ]];then
				CurrPer=0
			elif [[ $CurrSample -eq $LoopEnd ]];then
				CurrPer=100
			else
				CurrPer=$(( $CurrPer + $SlicePer ))
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
		echo -e "\033[1A/dev/$CurrDisk$UNRAIDSlot: $diskavgspeed MB/sec avg\033[K"
		echo
		if [[ $log -eq 1 ]]; then
			echo "/dev/$CurrDisk$UNRAIDSlot: $diskavgspeed MB/sec avg" >> diskspeed.log
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
for (( slot=0; slot < 26; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
			if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
				if [[ $slot -eq 0 ]];then
					drivenum="Parity"
				else
					drivenum="Disk $slot"
				fi
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
			if [ "$CurrDisk" == "$CacheID" ]; then
				DiskName='Cache'
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

# Generate graph lines for drives in the array
DisksProcessed=0
for (( slot=0; slot < 26; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
			if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
				if [[ $slot -eq 0 ]];then
					drivenum="Parity"
				else
					drivenum="Disk $slot"
				fi
				data=$(<"/tmp/diskspeed.$CurrDisk.graph2")
				rm /tmp/diskspeed.$CurrDisk.graph2
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
			data=$(<"/tmp/diskspeed.$CurrDisk.graph2")
			rm /tmp/diskspeed.$CurrDisk.graph2
			DiskName=$CurrDisk
			if [ "$CurrDisk" == "$CacheID" ]; then
				DiskName='Cache'
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

echo -e -n "]});});</script></head><body><style type=\042text/css\042>body,td {font-family:Arial,Helvetica,sans-serif;font-size:13px;color:black;}</style><script src=\042http://code.highcharts.com/highcharts.js\042></script><script src=\042http://code.highcharts.com/modules/exporting.js\042></script><div align=\042center\042><table border=0 cellpadding=0 cellspacing=0><tr><td><div id=\042graph1\042 style=\042min-width: 310px; width: 1000px; height: 400px; margin: 0 auto;" >> "$outputfile"
if [[ $ShowGraph1 -eq 0 ]]; then
	echo -n "display:none" >> "$outputfile"
fi
echo -e "\042></div><div id=\042graph2\042 style=\042min-width: 310px; width: 1000px; height: 400px; margin: 0 auto\042></div>" >> "$outputfile"

echo "<b>Drive Identification</b><br><table border=0 cellpadding=0 cellspacing=0>" >> "$outputfile"

# Generate disk information for array drives
for (( slot=0; slot < 26; slot++ ))
do
	CurrDiskID=0
	for CurrDisk in ${DiskID[@]}
	do
		if [[ "${DiskAvg[$CurrDiskID]}" == "" ]]; then
			CurrDiskAvg=""
		else
			CurrDiskAvg="${DiskAvg[$CurrDiskID]}&nbsp;MB/sec&nbsp;avg"
		fi
		if [ "$slot" == "${ArrayLoc[$CurrDiskID]}" ];then
			if [[ $slot -eq 0 ]];then
				DiskName="Parity"
			else
				DiskName="Disk $slot"
			fi
			echo "<tr><td>$DiskName:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td align='right'>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
		fi
		let CurrDiskID++
	done
done
# Generate disk information for the cache drive
CurrDiskID=0
for CurrDisk in ${DiskID[@]}
do
	if [ "$CurrDisk" == "$CacheID" ];then
		echo "<tr><td>Cache:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td align='right'>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
	fi
	let CurrDiskID++
done
# Generate disk information for the drives outside of the array
CurrDiskID=0
for CurrDisk in ${DiskID[@]}
do
	skip=$(echo "$skipdrives$unraid" | grep $CurrDisk)
	if [[ "$skip" == "" ]]; then
		if [ "${ArrayLoc[$CurrDiskID]}" == "" ];then
			if [ "$CurrDisk" != "$CacheID" ];then
				echo "<tr><td>$CurrDisk:&nbsp;</td><td>${DriveID[$CurrDiskID]}&nbsp;&nbsp;</td><td align='right'>${DiskSize[$CurrDiskID]}</td><td align='right'>&nbsp;&nbsp;$CurrDiskAvg</td></tr>" >> "$outputfile"
			fi
		fi
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
if [ -e "/tmp/mdcmd" ];then
	rm /tmp/mdcmd
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
if [ -e "/tmp/inventory.txt" ];then
	rm /tmp/inventory.txt
fi

for CurrDisk in ${DiskID[@]}
do
	if [ -e "/tmp/diskspeed.include.$CurrDisk.txt" ];then
		rm /tmp/diskspeed.include.$CurrDisk.txt
	fi
	let CurrDiskID++
done
