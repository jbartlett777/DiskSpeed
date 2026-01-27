<CFTRY>

<CFSET HardDriveData=DeserializeJSON(FORM.json)>

<CFSET i=1>
<CFSET DriveData[i].Vendor=HardDriveData.Vendor>
<CFSET DriveData[i].Model=HardDriveData.Model>
<CFSET DriveData[i].Revision="">
<CFINCLUDE template="SubmitDriveCleanup.cfm">
<CFSET HardDriveData.Vendor=DriveData[i].Vendor>
<CFSET HardDriveData.Model=DriveData[i].Model>





<CFSET ModelDir=HardDriveData.Model>
<CFSET ModelDir=Replace(ModelDir,"/","-","ALL")>
<CFSET ModelDir=Replace(ModelDir,":","-","ALL")>
<CFSET Dir=RootDir & "\Drives\" & HardDriveData.Vendor & "\" & ModelDir>
<CFSET Dir2=RootDir & "\Submitted">



<CFSET DefaultJSON=SerializeJSON(HardDriveData.Config)>
<!--- <CFSET InfoJSON=SerializeJSON(HardDriveData.Info)> --->
<CFSET FN=HardDriveData.UserID>
<CFSET ImageData=BinaryDecode(HardDriveData.Image,"Base64")>>
<CFIF DirectoryExists(Dir) EQ "NO">
	<CFDIRECTORY action="create" directory="#Dir#" CreatePath="true" mode="755">
	<CFFILE action="write" file="#Dir#/default.json" output="#DefaultJSON#" addnewline="NO" mode="755">
	<!--- <CFFILE action="write" file="#Dir#\info.json" output="#InfoJSON#" addnewline="NO"> --->
	<CFSET ImageWrite(ImageData,"#Dir#/default.png",1)>
</CFIF>

<CFFILE action="write" file="#Dir#/#FN#_default.json" output="#DefaultJSON#" addnewline="NO" mode="755">
<!--- <CFFILE action="write" file="#Dir#\#FN#_info.json" output="#InfoJSON#" addnewline="NO"> --->
<CFSET ImageWrite(ImageData,"#Dir#/#FN#.png",1)>
<CFSET ImageWrite(ImageData,"#Dir2#/#FN#.#HardDriveData.Vendor#.#ModelDir#.png",1)>
<CFSET fileSetAccessMode("#Dir#/#FN#.png", "755")>
<CFSET fileSetAccessMode("#Dir2#/#FN#.#HardDriveData.Vendor#.#ModelDir#.png", "755")>
<CFIF FileExists("#Dir#/#FN#.png.hash")>
	<CFFILE action="Delete" file="#Dir#/#FN#.png.hash">
</CFIF>
<CFIF FileExists("#Dir2#/#FN#.png.hash")>
	<CFFILE action="Delete" file="#Dir2#/#FN#.png.hash">
</CFIF>


<CFOUTPUT>Submission successful!</CFOUTPUT>

<CFCATCH Type="Any">
	<CFOUTPUT>#CFCatch.Message# - #CFCatch.Detail#</CFOUTPUT>
</CFCATCH>
</CFTRY>