<CFPARAM name="FORM.SMARTOptIn" default="">
<CFPARAM name="URL.OptInPreview" default="">
<CFPARAM name="URL.SmartOptInSel" default="">

<!--- Load in saved Opt In status --->
<CFSET SMARTOptIn=ReadFile("/tmp/DiskSpeed/SMARTOptIn.txt")>


<!--- Save user's initial Opt In status --->
<CFIF FORM.SMARTOptIn NEQ "">
	<CFIF FORM.SMARTOptIn EQ "Yes">
		<CFFILE action="write" file="/tmp/DiskSpeed/SMARTOptIn.txt" output="Yes" addnewline="NO" mode="666">
	<CFELSEIF FORM.SMARTOptIn EQ "No">
		<CFFILE action="write" file="/tmp/DiskSpeed/SMARTOptIn.txt" output="No" addnewline="NO" mode="666">
	<CFELSEIF FORM.SMARTOptIn EQ "Delete">
		<CFFILE action="write" file="/tmp/DiskSpeed/SMARTOptIn.txt" output="Delete" addnewline="NO" mode="666">
	</CFIF>
	<CFLOCATION URL="ScanControllers.cfm" addtoken="NO">
</CFIF>

<CFIF ListFindNoCase("Yes,No,Delete",SMARTOptIn) AND URL.SmartOptInSel NEQ "Info" AND URL.OptInPreview NEQ "Y">
	<CFEXIT>
</CFIF>


<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<title>DiskSpeed</title>
<style type="text/css">
body {font-family:Arial, Helvetica, sans-serif;}
td {font-family:Arial, Helvetica, sans-serif;}
.Bold {font-weight:bold;}
.Size14 {font-size:14px;}
.Size18 {font-size:18px;}
.Size24 {font-size:24px;}
.Red {color:red;}
.Hand {cursor:pointer;}
.NOBR {white-space:nowrap;}
.Underline {text-decoration:underline;}
</style>
</head>
<body>
</CFOUTPUT>
<CFINCLUDE template="DispHeader.cfm">
<CFOUTPUT>
<table border="0" style="max-width:1000px;" cellpadding="0" cellspacing="0">
	<tbody>
		<tr>
			<td>
				<span class="Size18 Underline">Drive S.M.A.R.T. Data Opt In / Out</span><br>
				<br>
				Soon, the drive health history data from <a href="https://www.backblaze.com/cloud-storage/resources/hard-drive-test-data" target="_blank">BackBlaze</a>
				will be displayed on this applications companion site, the <a href="#StrangeJourney#/hddb/" target="_blank">Hard Drive Database</a>.
				This data reveals reliability trends of hard drives used by BackBlaze such as how often a particular model fails each year.<br>
				<br>
				I would like to contribute to this data analysis effort by tracking the SMART data by users of the DiskSpeed application. If you chose to Opt In to this,
				the SMART data will be collected every time your hardware is scanned by DiskSpeed and anonymously uploaded to the HDDB server. Any subsequent upload of
				a drives SMART data will overwrite the previous so only the most recent is stored. Each drive is identified by a SHA1 hash of it's vendor, model, revision, &amp; serial number.<br>
				<br>
				You may change your choice to either Opt In or Out on the Hardware Scan screen. Upon Opting Out, you also have the choice to remove your SMART records from the HDDB server.<br>
				<br>
				<a href="ScanControllers.cfm?OptInPreview=Y">Preview the submitted SMART data</a> - you can view the full submitted data in file smartdata.zip on your Docker assigned persistant storage.
				Unzipping it into smartdata.json &amp; Viewing it in Firefox or using the JSON Notepad++ plugin will make it easier to read like the formatted preview if shown.<br>
				<br>
				<span class="Bold">Opt In to submit the SMART data?</span><br>
				<form action="SMARTOptIn.cfm" method="post">
				<input type="Radio" name="SMARTOptIn" value="Yes"<CFIF SMARTOptIn EQ "Yes"> CHECKED</CFIF>> Yes<br>
				<input type="Radio" name="SMARTOptIn" value="No"<CFIF SMARTOptIn EQ "No"> CHECKED</CFIF>> No<br>
				<CFIF SMARTOptIn EQ "Yes">
					<input type="Radio" name="SMARTOptIn" value="Delete"<CFIF SMARTOptIn EQ "No"> CHECKED</CFIF>> No, and delete my information<br>
				</CFIF>
				<br>
				<CFIF URL.SmartOptInSel EQ "Info">
					<input type="Submit" value="Update Choice">&nbsp;&nbsp;&nbsp;&nbsp;
					<input type="button" value="Exit, No Change" onClick="document.location='index.cfm';">
				<CFELSE>
					<input type="Submit" value="Save Choice">&nbsp;&nbsp;&nbsp;&nbsp;
				</CFIF>
			</td>
		</tr>
	</tbody>
</table>
<br>
</CFOUTPUT>
<CFFLUSH>

<CFIF URL.OptInPreview EQ "Y">
	<CFOUTPUT><div id="smart">Gathering SMART information: Spinning up drives...</div></CFOUTPUT><CFFLUSH>
	<CFINCLUDE template="Spinup.cfm">
	<CFOUTPUT>
	<script>document.getElementById('smart').innerHTML='Gathering SMART information: Retrieving SMART information';</script>
	</CFOUTPUT>
	<CFFLUSH>
	<CFINCLUDE TEMPLATE="SubmitSMARTData.cfm">

	<!--- Identify a spinner --->
	<CFLOOP index="ID" list="#StructKeyList(SMARTData)#">
		<CFSET UseID=ID>
		<CFIF SMARTData[UseID].nvme EQ 0 AND FindNoCase("SSD",SMARTData[UseID].model) EQ 0>
			<CFBREAK>
		</CFIF>
	</CFLOOP>

	<CFSET JSON=SerializeJSON(SMARTData[UseID])>
<!---	<CFSET JSON=Replace(JSON,",","," & Chr(10),"ALL")>--->

	<CFOUTPUT>
	<script>
	document.getElementById('smart').style.display='none';
	</script>
	<b>Preview of SMART submission</b><br>
	<small>Drive ID: #UseID# (this is your #SMARTDataBlock[UseID]# drive)</small><br>
	<pre>#formatJSON(JSON)#</pre>
	</CFOUTPUT>
</CFIF>
<CFOUTPUT>
</body>
</html>
</CFOUTPUT>
<CFFLUSH>

<cfscript>
/**
 * Formats a JSON string with indents &amp; new lines.
 * v1.0 by Ben Koshy
 * 
 * @param str      JSON string (Required)
 * @return Returns a string of indent-formated JSON 
 * @author Ben Koshy (cf@animex.com) 
 * @version 0, September 16, 2012 
 */
// formatJSON() :: formats and indents JSON string
// based on blog post @ http://ketanjetty.com/coldfusion/javascript/format-json/
// modified for CFScript By Ben Koshy @animexcom
// usage: result = formatJSON('STRING TO BE FORMATTED') OR result = formatJSON(StringVariableToFormat);

public string function formatJSON(str) {
    var fjson = '';
    var pos = 0;
    var strLen = len(arguments.str);
    var indentStr = chr(9); // Adjust Indent Token If you Like
    var newLine = chr(10); // Adjust New Line Token If you Like <BR>
    
    for (var i=1; i<strLen; i++) {
        var char = mid(arguments.str,i,1);
        
        if (char == '}' || char == ']') {
            fjson &= newLine;
            pos = pos - 1;
            
            for (var j=1; j<pos; j++) {
                fjson &= indentStr;
            }
        }
        
        fjson &= char;    
        
        if (char == '{' || char == '[' || char == ',') {
            fjson &= newLine;
            
            if (char == '{' || char == '[') {
                pos = pos + 1;
            }
            
            for (var k=1; k<pos; k++) {
                fjson &= indentStr;
            }
        }
    }
	fjson=Replace(fjson,Chr(10),Chr(10)&Chr(9),"ALL");
	fjson=fjson & Chr(10) & "}";
    return fjson;
}
</cfscript>

<CFABORT>
