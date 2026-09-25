<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>

<CFSET Key=ListFirst(FORM.Drive,"|")>
<CFSET PortNo=ListLast(FORM.Drive,"|")>

<CFSET Image=ImageReadBase64(ListDeleteAt(FORM.ImgData,1,","))>
<CFSET OrigImage=Image>
<CFSET ImageResize(Image,128)>
<CFSET ImgInfo=ImageInfo(Image)>

<!--- Check to see if the image is too tall --->
<CFIF ImgInfo.Height GTE 190>
	<CFIMAGE action="resize" height="190" source="#OrigImage#" name="ResImage">
	<CFSET ImgInfo=ImageInfo(ResImage)>
	<CFSET X=64-Int(ImgInfo.Width / 2)>
	<CFSET Image=ImageNew("",128,ImgInfo.Height,"rgb","FFFFFF")>
	<CFSET ImagePaste(Image,ResImage,X,0)>
	<CFSET ImgInfo=ImageInfo(Image)>
</CFIF>

<CFSET OutFN=PersistDir & "/driveinfo/" & HW[Key].Ports[PortNo].Config.SaveDir & "/image.png">
<CFSET ImageWrite(Image,OutFN,1)>

<CFSET OutFN=RootDir & "/images/inuse/" & CurrInstance & "/" & HW[Key].Ports[PortNo].Config.SaveDir & ".png">
<CFSET ImageWrite(Image,OutFN,1)>

<CFSET HW[Key].Ports[PortNo].Config.DriveEdited=1>
<CFSET HW[Key].Ports[PortNo].Config.ImageWidth=ImgInfo.Width>
<CFSET HW[Key].Ports[PortNo].Config.ImageHeight=ImgInfo.Height>
<CFSET HW[Key].Ports[PortNo].Config.Random=GetTickCount()>
<CFSET json=SerializeJSON(HW)>
<CFFILE action="write" file="#PersistDir#/storage.json" output="#json#" addnewline="NO" mode="666">

<CFOUTPUT>
<!DOCTYPE html>
<html>
<body>
<script>
parent.location.href='/index.cfm?Drive=#Key#%7C#PortNo#&Edit=Y';
</script>
</body>
</html>
</CFOUTPUT>
