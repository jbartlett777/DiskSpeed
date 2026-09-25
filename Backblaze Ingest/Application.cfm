<CFSETTING requesttimeout="999999" enablecfoutputonly="true">

<CFSET SourceDir="G:/BackBlaze">
<CFSET ModelDir="G:/BackBlaze/Data/ByModel">
<CFSET RootDir=ExpandPath(".")>
<CFSET DSN="mysql">
<CFSET MySQLBinDir="C:\Program Files\MySQL\MySQL Server 9.2\bin">
<CFSET MySQLDataDir="C:\ProgramData\MySQL\MySQL Server 9.2\data">
<CFSET Request.QueryCacheDir=ModelDir & "/QueryCache">
<CFSET AppServer=Server.coldfusion.productname>

<!--- Elements in the Cache structure that are not drive models --->
<CFSET CacheStructIgnore="Headers,Tables,SerialID">
<!--- Elements in the Cache[Model] that are informational --->
<CFSET CacheModelStructIgnore="Capacity,Columns,Header,ModelID,SMARTIDs">

<!--- List of tracked SMART IDs across all drives --->
<CFSET SMARTIDs="1,2,3,4,5,7,8,9,10,11,12,13,15,16,17,18,22,23,24,27,71,82,90,160,161,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,206,210,211,212,218,220,222,223,224,225,226,230,231,232,233,234,235,240,241,242,244,245,246,247,248,250,251,252,254,255">

<CFSET IgnoreModels="DELLBOSS_VD,_00md00,CT250MX500SSD1,Cache">

<CFSET Request.DSN=DSN>

<CFINCLUDE template="UDF.cfm">
<CFINCLUDE template="Timer.cfm">

<!--- Determine if the datasources allows multiple SQL statements --->
<CFTRY>
	<CFQUERY name="Test" datasource="#DSN#">
		SELECT 1; SELECT 2;
	</CFQUERY>
	<CFSET MultiSQL=1>
	<CFCATCH Type="Database">
		<CFSET MultiSQL=0>
	</CFCATCH>
</CFTRY>
