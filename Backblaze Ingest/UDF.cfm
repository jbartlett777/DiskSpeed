<CFFUNCTION name="CSVToQuery" output="true">
	<CFARGUMENT name="Headers" type="string" required="true" hint="Headers, comma delimited">
	<CFARGUMENT name="HeaderSpec" type="string" required="true" hint="Column types, comma delimited">
	<CFARGUMENT name="Data" type="string" required="true" hint="Raw CSV data without header row, line delimited with LF">

	<CFSET VAR CSVRegEx='"(?:[^"]|"")*"|[^,]*(?=,|$)'>
	<CFSET VAR Q=QueryNew(Arguments.Headers,Arguments.HeaderSpec)>
	<CFSET VAR Line="">
	<CFSET VAR LineMatch="">
	<CFSET VAR HeaderStruct="[{""" & Replace(Arguments.Headers,",",""":""~*`"",""","All") & """:""~*`""}]">
	<CFSET VAR RowStruct="">
	<CFSET VAR Col=0>

	<cfoutput>#HeaderStruct#</cfoutput>
<!---{"id":1,"title":"Dewey defeats Truman"}, {"id":2,"title":"Man walks on Moon"} ]);--->
	<CFLOOP index="Line" list="#Arguments.Data#" delimiters="#Chr(10)#">
		<CFSET LineMatch=REMatch(CSVRegEx,Line)>
		<CFSET RowStruct=HeaderStruct>
		<CFLOOP index="Col" from="1" to="#ArrayLen(LineMatch)#">
			<CFSET RowStruct=Replace(RowStruct,"~*`",LineMatch[Col],"One")>
		</CFLOOP>
		<!--- Append Row to query --->
		<cfdump var=#RowStruct#>
		<CFSET QueryAddRow(Q,RowStruct)>
	</CFLOOP>

	<CFRETURN Q>
</CFFUNCTION>


<CFFUNCTION Name="CacheDrives">

	<CFSET VAR serial_numbers="">
	<CFSET VAR Cache=StructNew()>
	<CFSET VAR CR=0>
	<CFSET VAR Model="">
	<CFSET VAR SerialNum="">

	<CFQUERY name="serial_numbers" datasource="#DSN#" blockfactor="100">
		SELECT s.SerialID, s.Dupe, s.ModelID, m.Model, m.SchemaName, s.Serial_Number, s.FirstDate, s.LastDate, s.Failed, IfNull(s.PartitionID,0) as PartitionID
		FROM backblaze2.serial_numbers s
		INNER JOIN backblaze2.models m ON m.ModelID=s.ModelID
		ORDER BY m.Model, s.PartitionID, s.Serial_Number
	</CFQUERY>

	<CFLOOP index="CR" from="1" to="#serial_numbers.RecordCount#">
		<CFSET Model=serial_numbers.Model[CR]>
		<CFSET SerialNum=serial_numbers.Serial_Number[CR]>
		<CFIF StructKeyExists(Cache,Model) EQ "NO">
			<CFSET Cache[Model]=StructNew()>
			<CFSET Cache[Model].SchemaName=serial_numbers.SchemaName[CR]>
			<CFSET Cache[Model].ModelID=serial_numbers.ModelID[CR]>
			<CFSET Cache[Model].Capacity=StructNew()>
		</CFIF>
		<CFSET Cache[Model][SerialNum]=StructNew()>
		<CFSET Cache[Model][SerialNum].SerialID=Replace(RJustify(serial_numbers.PartitionID,3)," ","0","All") & "|" & Replace(RJustify(serial_numbers.SerialID[CR],8)," ","0","All")> <!--- Zero pad partition id & serial id for sorting --->
		<CFSET Cache[Model][SerialNum].Dupe=serial_numbers.Dupe[CR]>
		<CFSET Cache[Model][SerialNum].FirstDate=serial_numbers.FirstDate[CR]>
		<CFSET Cache[Model][SerialNum].LastDate=serial_numbers.LastDate[CR]>
		<CFSET Cache[Model][SerialNum].Failed=serial_numbers.Failed[CR]>
	</CFLOOP>

	<CFRETURN Cache>

</CFFUNCTION>


<CFSET CreatePathChecked=ArrayNew(1)>
<CFFUNCTION name="CreatePath">
	<CFARGUMENT name="Path" type="string" required="true" hint="Full path to create if not defined">
	<CFARGUMENT name="Mode" type="string" required="false" default="666">

	<CFSET VAR CheckPath=Replace(Arguments.Path,"\","/")>
	<CFSET VAR CurrPath="">
	<CFSET VAR i=0>

	<!--- Handle where the directory tree is pre-cached --->
	<CFIF StructKeyExists(Variables,"CachePaths")>
		<CFIF ArrayContains(CachePaths,Arguments.Path)>
			<CFRETURN false>
		</CFIF>
		<CFSET ArrayAppend(CachePaths,Arguments.Path)>
		<CFIF AppServer EQ "Lucee">
			<CFDIRECTORY action="create" directory="#Arguments.Path#" createpath="true">
			<CFRETURN true>
		</CFIF>
	</CFIF>

	<!--- If we already checked the path this run, exit --->
	<CFIF ArrayContainsNoCase(CreatePathChecked,CheckPath)>
		<CFRETURN false>
	</CFIF>

	<CFIF DirectoryExists(CheckPath)>
		<!--- If the directory exists as-is, no need to scan the path --->
		<CFSET ArrayAppend(CreatePathChecked,CheckPath)>
		<CFRETURN false>
	</CFIF>

	<CFLOOP index="i" from="1" to="#ListLen(CheckPath,'/')#">
		<CFSET CurrPath=ListAppend(CurrPath,ListGetAt(CheckPath,i,"/"),"/")>
		<CFIF DirectoryExists(CurrPath) EQ "NO">
			<CFDIRECTORY action="create" directory="#CurrPath#" mode="#Arguments.Mode#">
		</CFIF>
	</CFLOOP>
	<CFSET ArrayAppend(CreatePathChecked,CheckPath)>

	<CFRETURN true>

</CFFUNCTION>

<CFFUNCTION name="Out">
	<CFARGUMENT name="txt" type="string" required="true" hint="Text to update status info with">
	<CFSET VAR Encoded=EncodeForJavascript(Arguments.Txt)>
	<CFSET Encoded=Replace(Encoded,"\x20"," ","All")>
	<CFOUTPUT><script>S('#TS()# #Encoded#');</script>#Chr(10)#</CFOUTPUT>
	<CFFLUSH>

	<CFRETURN>
</CFFUNCTION>

<CFFUNCTION name="GetCachedColType">
	<CFARGUMENT name="Schema" type="string" required="true">
	<CFARGUMENT name="Column" type="string" required="true">

	<CFIF StructKeyExists(Cache.Tables,Arguments.Schema)>
		<CFIF StructKeyExists(Cache.Tables[Arguments.Schema],Arguments.Column)>
			<CFIF Cache.Tables[Arguments.Schema][Arguments.Column] EQ "null">
				<CFRETURN "bigint">
			<CFELSE>
				<CFRETURN Cache.Tables[Arguments.Schema][Arguments.Column]>
			</CFIF>
		</CFIF>
	</CFIF>

	<CFRETURN "BIGINT">

</CFFUNCTION>

<CFFUNCTION name="SafeSchemaName" hint="Converts a model name into a MySQL safe schema name">
	<CFARGUMENT name="ModelName" type="string" required="true" hint="Drive Model to make safe for MySQL">
	<CFSET VAR Safe="">
	<CFSET Safe=REREplaceNoCase(Arguments.ModelName,"[^a-z0-9\s]","")>
	<CFSET Safe=Replace(Safe," ","_","All")>
	<CFLOOP condition="Find('__',Safe)">
		<CFSET Safe=Replace(Safe,"__","_","All")>
	</CFLOOP>
	<CFRETURN Safe>
</CFFUNCTION>

<!--- Init the SQL directory which holds all SQL files created during processing --->
<CFIF DirectoryExists("#ModelDir#/SQL") EQ "NO">
	<CFDIRECTORY action="Create" directory="#ModelDir#/SQL" mode="666">
</CFIF>
<CFDIRECTORY action="List" directory="#ModelDir#/SQL" type="File" filter="*.sql" name="SQLCntDir">
<CFSET SQLCnt=SQLCntDir.RecordCount>
<CFSET StructDelete(Variables,"SQLCntDir")>

<cfscript>
function Hash36(txt)
{
	// Returns a short 6 character psudo-hash value in base 36, saves user having to copy 4 Hash Hex strings 128 characters long
	// InputBaseN can't handle a full Hash value, break it up
	var H=Hash(Arguments.txt);
	var H1=InputBaseN(Left(H,4),16);
	var H2=InputBaseN(Mid(H,8,4),16);
	var H3=InputBaseN(Mid(H,12,4),16);
	var H4=InputBaseN(Mid(H,16,4),16);
	var H5=InputBaseN(Mid(H,20,4),16);
	var H6=InputBaseN(Mid(H,24,4),16);
	var H7=InputBaseN(Mid(H,28,4),16);
	return UCase(Replace(RJustify(FormatBaseN(H1+H2+H3+H4+H5+H6+H7,36),4)," ","0","ALL"));
}

function ts() {
	return TimeFormat(Now(),"HH:mm:ss");
}

function GetSQLCnt() {
	// Returns the current value of SQLCnt right justified to 10 places and zero padded
	return Replace(RJustify(SQLCnt,10)," ","0","All");
}

/**
// From https://cflib.org/udf/formatJSON with correction from "Mary" and "Mr Namako" shown on cflib.org plus additional updates by John Bartlett:
*	Do not add line feeds after escaped quotes
*	Hanlde large JSON by splitting up the return string into two variables due esponently longer processing on appending onto larger strings
*	Ignore JSON characters if inside a quoted string
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

public string function formatJSON(instr) {
	var str=arguments.instr;
	var char=""; // Current char being processed
	var fjson = ''; // Output hold variables
	var fjson2 = '';
	var pos = 0;
	var i=0;
	var j=0;
	var k=0;
	var strLen = 0;
	var indentStr = chr(9); // Adjust Indent Token If you Like
	var newLine = chr(10); // Adjust New Line Token If you Like <BR>
	var InQuote=0;
	var QuoteScan="";

	if (IsJSON(str) EQ "NO") return "Not a JSON object";

	strLen = len(str);

	for (i=1; i<=strLen; i++) {
		char = mid(str,i,1);
		if (char EQ Chr(34) AND mid(str,i-1,1) NEQ "\") {
			// Flag if inside a quote or not
			InQuote = 1 - InQuote;
		}

		if (char == '}' || char == ']') {
			if (InQuote EQ 0) {
				fjson &= newLine;
				pos = pos - 1;

				for (j=1; j<=pos; j++) {
					fjson &= indentStr;
				}
			}
		}

		fjson &= char;

		if (ListFind(",|{|[",char,"|") AND InQuote EQ 0) {

			fjson &= newLine;

			if (char == '{' || char == '[') {
				pos = pos + 1;
			}

			for (k=1; k<=pos; k++) {
				fjson &= indentStr;
			}
		}

		// If the string exceeds 10K, append to fjson2 and clear fjson to avoid the exponential delay in appending to a large string in java
		if (Len(fjson) GT 10240) {
			fjson2=fjson2 & fjson;
			fjson="";
		}
	}

	fjson2 &= fjson;
	// Add space prior to brackets
	fjson2=Replace(fjson2,":{",": {","All");
	fjson2=Replace(fjson2,":[",": [","All");
	return fjson2;
}

function KBytes(bytes)
{
	var b=0;
	var NF="9,999";
	if (ArrayLen(Arguments) GT 1) NF=Arguments[2];

	if(Abs(arguments.bytes) lt 1000) return trim(numberFormat(arguments.bytes,"9,999")) & " bytes";

	b=arguments.bytes / 1000;

	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " KB";
		return trim(numberFormat(b,NF)) & " KB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " MB";
		return trim(numberFormat(b,NF)) & " MB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " GB";
		return trim(numberFormat(b,NF)) & " GB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " TB";
		return trim(numberFormat(b,NF)) & " TB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " PB";
		return trim(numberFormat(b,NF)) & " PB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " EB";
		return trim(numberFormat(b,NF)) & " EB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " ZB";
		return trim(numberFormat(b,NF)) & " ZB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " YB";
		return trim(numberFormat(b,NF)) & " YB";
	}
}
</cfscript>
