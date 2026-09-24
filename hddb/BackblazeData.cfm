<!--- Load in TeleportHQ page --->
<CFFILE action="read" file="#RootDir#/Templates/back-blaze-data-rendered.html" variable="HTML">
<CFINCLUDE template="GlobalHTMLFix.cfm">

<CFSET HTML=REReplaceNoCase(HTML,"<a\s+?href=""https:\/\/javascript:void\(0\)[\w\s\d\W\S\D]*?Failure Rates by Age\s+?<\/a>","<a href=""javascript:void(0);"" onClick=""View('FailureRates')"">Failure Rates by Age</a>")>
<CFSET HTML=Replace(HTML,"src=""https://www.strangejourney.net""","src=""blank.html""")>

<!--- Javascript for before the page --->
<CFSAVECONTENT variable="JS">
<CFOUTPUT>
<script>
function View(Page) {
	document.getElementById('ModelFrame').src='/hddb/BackBlaze/' + Page + '.cfm';
}
</script>
</CFOUTPUT>
</CFSAVECONTENT>
<CFSET HTML=ReplaceNoCase(HTML,"</head>","#JS#</head>")>


<CFOUTPUT>#HTML#</CFOUTPUT>