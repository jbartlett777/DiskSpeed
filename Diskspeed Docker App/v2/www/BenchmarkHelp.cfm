<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<style type="text/css">
body {font-family:Arial, Helvetica, sans-serif;}
td {font-family:Arial, Helvetica, sans-serif;}
</style>
</head>
<body>
<h2>Solid State Drive Benchmarking</h2>
Solid State Drives (SSD) are rated by the manufacturer for a given read & write speed. This value is typically the theoretically maximum transfer speed which doesn't exactly
match actual usage, and your machine might not be able to utilize the SSD to the degree another system might be able to. This benchmark will reflect your system's
transfer speed reading & writing to the SSD.<br>
<br>
<b>SSD's must be mounted in the Host OS running Docker and a path to the drive's mount point passed in the Docker settings to be benchmarkable.</b><br>
<br>
Under UNRAID, use Unassigned Devices to mount the SSDs and edit the DiskSpeed configuration to add a Path variable:

<blockquote>
	<u>UNRAID Docker Path Values</u><br>
	Config Type: Path<br>
	Name: UNRAID<br>
	Container Path: /mnt/UNRAID<br>
	Host Path: /mnt<br>
	Access Mode: Read/Write
</blockquote>
For other Docker installations, an example is <font face="Courier New">-v '/mnt':'/mnt/Host':'rw'</font> if you have all your SSD's mounted under /mnt.<br>
<br>
If you make any changes to the mounted devices on the Host such as editing the partitions, you will need to restart the DiskSpeed Docker application for it to see the changes.<br>
<br>
<h3>How the SSD Benchmark works</h3>
SSD benchmarking in this application is done by spawning 4 tasks, each creating 4 files (total of 16) to maximize the bus between the drive controller and the drive itself,
then repeating that process up to #SSDBenchmarkTestFiles_Default# times. If consistent results are received enough times in a row, the write portion of the benchmark is ended
to start the read portion.<br>
<br>
This benchmark attempts to force the drive to ignore any write cache but not every drive honors those commands in the attempt to give the appearance of better
performance. Two ways to identify this is unusual spikes or dips in the different tests.<br>
<br>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td colspan="3" align="center">
			<b>Drives Ignoring No Cache Examples</b>
		</td>
	</tr>
	<tr>
		<td valign="top">
			<table border="1" cellpadding="5" cellspacing="0" width="300">
				<tr>
					<td align="justify">
						<img src="images/SSDWriteCache.png" width="300"><br>
						The drive is buffering write data in a cache prior to writing to mask slower memory chips, even though it was instructed bypass any buffer.
					</td>
				</tr>
			</table>
		</td>
		<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
		<td valign="top">
			<table border="1" cellpadding="5" cellspacing="0" width="300">
				<tr>
					<td align="justify">
						<img src="images/SSDWriteCache2.png" width="300"><br>
						The drive ignored a command to flush the write buffer while responding that it did flush, allowing reading of files.
						Read speeds are impacted until the write buffer is cleared.
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
<br>
To accommodate for such drives and to allow the expected consistent results from a benchmark, the read test will wait a default of 10 seconds to allow for any hidden
write buffer to clear. Your drive may need to have a longer duration than 10 seconds if you still see the read dip on the 2nd example.<br>
<br>
SSD benchmarks are performed one at a time due to the simple fact that benchmarking multiple high speed devices at the same time will cause system bus saturation
which will impact the test results. As soon as one SSD is done benchmarking, the next SSD in line will automatically start.<br>
<br>
If one or more SSD's exist on a SATA/SAS controller, they will be benchmarked before non-SSD drives. This may cause a delay on other controllers if they
have mixed use of SSD and Spinner drives.<br>
<br>
<h2>Standard Platter Drive Media Drives Benchmarking</h2>
Since hard drives with physical media are designed to have fixed locations where sector zero is (almost) always at the start of the drive, benchmarking such
drives is much easier and straight forward. At the default specification of 10%, the drive is directly read every 10% including the start and the end for a total
of 11 test spots. A 1TB drive will be tested at 0GB, 100GB, 200GB, 300GB, 400GB, 500GB, 600GB, 700GB, 800GB, and roughly 999.9GB, or the amount of data read at the 90%
mark subtracted from the end of the drive.<br>
<br>
Benchmark graphs will start high and progressively get slower towards the end of the drive. If you have a graph that starts high and maintains the same speed for
multiple test spots, then you are likely bandwidth constrained and the drive is capable of pushing more data than the controller you're using. Running a benchmark
every so often will let you compare them over time and it will be easy to notice any degradation in quality.<br>
</body>
</html>
</CFOUTPUT>