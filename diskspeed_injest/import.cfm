
<cfabort>
<CFFILE action="read" file="#RootDir#/seagate/info.txt" variable="data">
<CFSET Data=StripCR(data)>
<CFLOOP index="CurrLine" list="#Data#" delimiters="#Chr(10)#">
	<CFIF Left(CurrLine,1) NEQ "##">
		<CFSET Model=ListGetAt(CurrLine,1,"|")>
		<CFSET Interface=ListGetAt(CurrLine,2,"|",1)>
		<CFSET RPM=ListGetAt(CurrLine,3,"|",1)>
		<CFSET Cache=ListGetAt(CurrLine,4,"|",1)>
		<CFSET Image=ListLast(ListGetAt(CurrLine,5,"|",1),"/")>
		<CFIF IsNumeric(RPM) EQ "NO">
			<CFSET RPM="NULL">
		</CFIF>
		<CFIF IsNumeric(Cache) EQ "NO">
			<CFSET Cache="NULL">
		</CFIF>
		<CFOUTPUT>#Model#, #InterFace#, #RPM#, #Cache#, #Image#<br></CFOUTPUT>
		<CFQUERY datasource="#DSN#">
			INSERT INTO DiskSpeed.Models
				(BrandID, Model, Interface, RPM, Cache, Image)
			VALUES
				(4,'#Model#','#Interface#',#RPM#,#Cache#,'#Image#')
		</CFQUERY>
	</CFIF>
</CFLOOP>
