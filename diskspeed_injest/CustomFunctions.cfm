<cfscript>
function ReturnRegExAsString(reg,txt)
{
	var Match=REMatch(Arguments.Reg,Arguments.txt);
	var i=0;
	var RetStr="";
	var Sep="";

	if (ArrayLen(Arguments) EQ 3) Sep=Arguments[3];

	for (i=1;i LTE ArrayLen(Match);i=i+1)
	{
		if (i LT ArrayLen(Match))
		{
			if (Len(Match[i])) RetStr=RetStr & Match[i] & Sep;
		} else {
			RetStr=RetStr & Match[i];
		}
	}

	return RetStr;
}
function NULLNumber(n)
{
	if (IsNumeric(Arguments.n) EQ "NO") return "null";
	return Arguments.n;
}
function TS() {
	return TimeFormat(Now(),"HH:mm:ss");
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