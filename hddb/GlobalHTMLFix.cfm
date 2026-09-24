<!--- Replace baseline references --->
<CFSET HTML=Replace(HTML,"href=""./","href=""/hddb/Templates/","ALL")>
<CFSET Blocks1=REMatchNoCase('<link rel="stylesheet" href="\.\/.+?\/>',HTML)>
<CFSET Blocks2=REMatchNoCase('<link href="\.\/.+?" rel="stylesheet" \/>',HTML)>
<CFSET ArrayAppend(Blocks1,Blocks2,true)>
<CFLOOP index="i" from="1" to="#ArrayLen(Blocks1)#">
	<CFSET HTML=Replace(HTML,Blocks1[i],Replace(Blocks1[i],'./','/hddb/Templates/','ALL'),'ALL')>
</CFLOOP>

<!--- Replace page links --->
<CFSET HTML=Replace(HTML,"index.html","index.cfm","ALL")>
<CFSET HTML=Replace(HTML,"brand-images.html","BrandImages.cfm","ALL")>
<CFSET HTML=Replace(HTML,"model-database.html","ModelDatabase.cfm","ALL")>
<CFSET HTML=Replace(HTML,"back-blaze-data.html","BackblazeData.cfm","ALL")>

<!--- Misc corrections --->
<CFSET HTML=Replace(HTML," null","","ALL")>
<CFSET HTML=Replace(HTML,"[DiskSpeed]","<a href=""https://forums.unraid.net/topic/70636-diskspeed"">DiskSpeed</a>")>
<CFSET HTML=Replace(HTML,"=;","=null;","All")>
