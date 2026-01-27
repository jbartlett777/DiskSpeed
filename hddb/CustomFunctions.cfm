<cfscript>
function KBytes(bytes)
{
	var b=0;
	var NF="9,999.99";
	var ReturnIntForScale="";
	
	if (NOT IsNumeric(Arguments.bytes)) return "-1";
	
	if (ArrayLen(Arguments) GT 1) NF=Arguments[2];
	if (ArrayLen(Arguments) GT 2) ReturnIntForScale=Arguments[3];

	if(Abs(arguments.bytes) lt 1000) return trim(numberFormat(arguments.bytes,"9,999")) & " bytes";

	b=arguments.bytes / 1000;

	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b)) OR ListFindNoCase(ReturnIntForScale,"KB")) return int(b) & " KB";
		return trim(numberFormat(b,NF)) & " KB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b)) OR ListFindNoCase(ReturnIntForScale,"MB")) return int(b) & " MB";
		return trim(numberFormat(b,NF)) & " MB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b))) return b & " GB";
		if(Abs(b) eq int(Abs(b)) OR ListFindNoCase(ReturnIntForScale,"GB")) return int(b) & " GB";
		return trim(numberFormat(b,NF)) & " GB";
	}
	b= b / 1000;
	if (Abs(b) lt 1000) {
		if(Abs(b) eq int(Abs(b)) OR ListFindNoCase(ReturnIntForScale,"TB")) return int(b) & " TB";
		return trim(numberFormat(b,NF)) & " TB";
	}
	b= b / 1000;
	if(Abs(b) eq int(Abs(b)) OR ListFindNoCase(ReturnIntForScale,"PB")) return int(b) & " PB";
	return trim(numberFormat(b,NF)) & " PB";
}
</cfscript>

<cffunction name="IsUnicode" returntype="Any">
    <cfargument name="Txt" required="true" type="string">

    <CFSET VAR CR=0>
    <CFSET VAR Return=0>

    <CFLOOP index="CR" from="1" to="#Len(Arguments.Txt)#">
        <CFIF Asc(Mid(Arguments.Txt,CR,1)) GT 126>
            <CFSET Return=1>
            <CFBREAK>
        </CFIF>
    </CFLOOP>

    <CFRETURN Return>
</cffunction>
