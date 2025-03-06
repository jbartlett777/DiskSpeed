# Hard Drive & Controller Benchmarking

DiskSpeed is a Lucee application running in a Docker container that can perform benchmarking of system controllers & hard drives.

<a href="https://www.strangejourney.net/github/diskspeed/DiskSpeed_Main.png" target="_blank"><img src="https://www.strangejourney.net/github/diskspeed/DiskSpeed_Main_thumb.png"></a><br>
(click thumbnails for larger images)

DiskSpeed was designed to run on UNRAID and has support for the UNRAID OS but should also work fine under any unix OS. Windows is not supported as the app requires privliged mode in order to scan the hardware which Windows does not support.

## Drive Controller Benchmarking
Drive controllers are identified and the ports scanned to see what drives, if any, are attached. The controller can be tested to see if the drives attached are capable of saturating its bandwidth by performing a 15 second benchmark on each drive in sequence,
then reading all drives simultaneously and comparing the results. If the simultaneous scan is showing lower read rates, it is possible for it to bottleneck. On the UNRAID OS, performing a parity scan on the UNRAID array involves reading all drives at the same
time and thus a controller bottleneck will increase the duration of the scan.

<a href="https://www.strangejourney.net/github/diskspeed/Controller_Benchmark.png" target="_blank"><img src="https://www.strangejourney.net/github/diskspeed/Controller_Benchmark_thumb.png"></a><br>

## Benchmarking Hard Drives

Benchmarking hard drives with spinning platters is done by reading the drive every 10% (default) of the drive including the start & end for 15 seconds giving you a basic speed curve over the surface of the drive. These benchmarks can be compared over time
and will indicate if a drive is failing if a benchmark is showing slower speeds than previously. If benchmarking multiple drives at once, only one drive per controller is tested and Solid State Drives will wait until they can be tested alone.

DiskSpeed will only perform read tests on a drive, not write tests.

**Benchmark with multiple like models and an unlike model**

Parity scans will operate at the speed of the slowest drive in the array. Even though drive "data6 (sdg)" has a clear speed advantage over the other drives, it will not impact any parity scan as it'll be slowed down to match the others.

<a href="https://www.strangejourney.net/github/diskspeed/SpinnerBenchmark1.png" target="_blank"><img src="https://www.strangejourney.net/github/diskspeed/SpinnerBenchmark1_thumb.png"></a><br>

Viewing an hard drive will display specific information derived from the drive itself. If the drive doesn't reveal it's RPM, a micro-benchmark is done to reveal it. WD-Green drives are known for this.
You can compare benchmarks taken at different dates to see if the drive is starting to perform poorly. Such signs of aging might not be evident in the SMART reports but can show up as a dip in a spot on the drive's read rate.

<a href="https://www.strangejourney.net/github/diskspeed/SpinnerBenchmark2.png" target="_blank"><img src="https://www.strangejourney.net/github/diskspeed/SpinnerBenchmark2_thumb.png"></a><br>

## Benchmarking Solid State Drives

Benchmarking solid state drives can't be done the same way as a hard drive. You can ask to read the drive at a given location but most SSD's will not even attempt to do so if that location has never been written to, leading to impossibly high speed results.
In order to test, large files with random data need to be written to the drive and then read back. This could arguably decrease the lifespan of the SSD so be aware of that, though I would also argue that the wear & tear is negligible.

During the write phase, up to 15 sets files are created and the write speeds are compared to the previous ones. Each set of files is comprised of four files that are written simultaneously that combined equal the total requested test set size. For NVMe drives,
the set defaults to 4GB and for SATA SSD drives, 1 GB. If enough files have the same write speed in a row, the write phase is ended early if 15 files haven't been written yet. After a short pause to allow any hidden caching to finish writing the data.

**SSD Benchmark Results**

<a href="https://www.strangejourney.net/github/diskspeed/SSDBenchmark1.png" target="_blank"><img src="https://www.strangejourney.net/github/diskspeed/SSDBenchmark1_thumb.png"></a>
<a href="https://www.strangejourney.net/github/diskspeed/SSDBenchmark2.png" target="_blank"><img src="https://www.strangejourney.net/github/diskspeed/SSDBenchmark2_thumb.png"></a>

After bnechmarking a SSD, you can view the details of each set of files by clicking on the drive's icon.

<a href="https://www.strangejourney.net/github/diskspeed/SSDBenchmark3.png" target="_blank"><img src="https://www.strangejourney.net/github/diskspeed/SSDBenchmark3_thumb.png"></a>

From these results, you can surmise that the drive either does not have any built-in cache or it honored the request to disable cache writes. If you see higher bars at the start and then dropping significantly, the drive is caching it's writes and ignoring the
cache bypass directive, typically to boost perceived performance..
