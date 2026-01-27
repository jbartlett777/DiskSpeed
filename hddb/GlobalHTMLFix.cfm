<!--- Replace baseline references --->
<CFSET HTML=Replace(HTML,"href=""./","href=""Templates/","ALL")>

<!--- Replace page links --->
<CFSET HTML=Replace(HTML,"index.html","index.cfm","ALL")>
<CFSET HTML=Replace(HTML,"brand-images.html","BrandImages.cfm","ALL")>
<CFSET HTML=Replace(HTML,"model-database.html","ModelDatabase.cfm","ALL")>
<CFSET HTML=Replace(HTML,"back-blaze-data.html","BackblazeData.cfm","ALL")>

<!--- Misc corrections --->
<CFSET HTML=Replace(HTML," null","","ALL")>
<CFSET HTML=Replace(HTML,"[DiskSpeed]","<a href=""https://forums.unraid.net/topic/70636-diskspeed"">DiskSpeed</a>")>
