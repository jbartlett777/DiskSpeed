# Diskspeed Development

The way I perform development on the DiskSpeed docker application is to run it on my backup NAS box with a mapping to the source code to
replace the self-contained www directory with my development instance. If testing new OS level utilities inside the docker, note that if
edit the docker settings in UNRAID, the docker image is recreated and any changes made at the OS level inside the container will be lost.

The built-in Lucee admin is at /lucee/admin/index.cfm and the password is "DiskSpeed", defined in the Dockerfile. Also note that the
above warning that changes will be lost on editing the Docker configuration will cause settings to reset which is also a good failsafe
if an edit crashes the Lucee server.
