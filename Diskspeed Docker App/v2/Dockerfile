#FROM lucee/lucee:6.1.1.75-SNAPSHOT
FROM lucee/lucee:6.2.8.20

# Copy DiskSpeed application
COPY www /var/www

# Install utilities
RUN apt-get update && \
	apt-get -y upgrade && \
	apt-get -y --no-install-recommends install pciutils nvme-cli lshw usbutils hdparm tree hwinfo ioping dmidecode inxi parted smartmontools cifs-utils nfs-common fio zfsutils-linux && \
	apt-get clean && \
	curl --url https://www.smartmontools.org/export/HEAD/trunk/smartmontools/drivedb.h --output /var/lib/smartmontools/drivedb/drivedb.h && \
	/usr/sbin/update-pciids && \
	wget -O /usr/share/misc/usb.ids http://www.linux-usb.org/usb.ids && \
	echo "DiskSpeed" > /opt/lucee/server/lucee-server/context/password.txt && \
	rm -rf /var/www/archive
