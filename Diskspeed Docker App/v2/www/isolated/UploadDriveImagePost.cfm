<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>

<CFSET Key=ListFirst(FORM.Drive,"|")>
<CFSET PortNo=ListLast(FORM.Drive,"|")>

<CFSET ImgSaveDir=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir>

<CFFILE action="upload" filefield="file" destination="#ImgSaveDir#" nameConflict="MakeUnique" result="Result">

<CFIF NOT Result.fileWasSaved>
</CFIF>
<CFSET FN=ImgSaveDir & "/" & Result.serverFile>
<CFSET RenameFile=1>
<CFIF IsImageFile(FN)>
	<CFSET OutFN=ImgSaveDir & "/user.png">
	<CFSET ImageData=ImageRead(FN)>
	<CFIF ImageGetWidth(ImageData) GT ImageGetHeight(ImageData)>
		<!--- Rotate image into Portrait mode --->
		<CFSET ImageFlip(ImageData,"90")>
	</CFIF>
	<CFSET ImageWrite(ImageData,OutFN,1)>
	<CFFILE action="delete" file="#FN#">
<CFELSE>
	<cfheader statuscode="500" statustext="File is not an image" /><CFABORT>
</CFIF>

