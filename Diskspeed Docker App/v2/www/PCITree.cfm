<cfexecute name="/usr/bin/lspci" arguments="-PPDmm" timeout="300" variable="lspci" />
<cfdump var=#lspci#>
