<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>

<CFSET Key=ListFirst(URL.Drive,"|")>
<CFSET PortNo=ListLast(URL.Drive,"|")>

<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<style type="text/css">
html {height:100%;}
body {font-family:Arial, Helvetica, sans-serif;height:100%;margin: 0 auto;}
.Bold {font-weight:bold;}
.FloatLeft {float:left;}
.dropzone {
    border: 2px dashed ##0087F7 !important;
    border-radius: 5px !important;
    background: white !important;
}
</style>
<link rel="stylesheet" href="/includes/dropzone.css">
<script type="text/javascript" src="/includes/dropzone.js"></script>
<script type="text/javascript">
Dropzone.options.dropzone = {
	paramName: 'file', // The name that will be used to transfer the file
	acceptedFiles: 'image/jpeg,image/png,image/tiff,image/bmp,image/gif',
	autoProcessQueue: true,
	createImageThumbnails: true,
	success: function(file, done)
		{
			window.location.href='/isolated/UploadDriveImage2.cfm?Drive=#URLEncodedFormat(URL.Drive)#'
		}
	};
</script>
</head>
<body>
<big><b>Upload new image for #HW[Key].Ports[PortNo].Attrib.Vendor# #HW[Key].Ports[PortNo].Attrib.Model# (#HW[Key].Ports[PortNo].Attrib.Serial#)</b></big>
<center>
<table border="0" cellpadding="0" cellspacing="0" width="75%" height="97%">
	<tr>
		<td align="center" valign="middle">
			<table border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td valign="top" rowspan="2"><img src="/images/UploadDemoImage.png" width="200"></td>
					<td rowspan="2">&nbsp;&nbsp;&nbsp;</td>
					<td valign="top">
						<span class="Bold">Upload Tips:</span><br>
						When searching for a drive image, pick one that has a view of the drive with a top-down view
						with no angling left or right to show the side of the device. The larger the image you choose,
						the better quality the resized version will be.<br>
						<br>
						Images with a transparant background are best, otherwise use one with a white background.<br>
						<br>
						Accepted image types: JPG, PNG, TIFF, BMP, GIF<br>
						<br>
						You don't need to pre-crop or rotate the image prior to uploading, you'll be given the option
						to crop the image in-line after you upload it before applying. If you decide you don't like
						the crop, you'll be able to reapply it to the original image.
					</td>
				</tr>
				<tr>
					<td align="center">
						<table border="0" cellspacing="0" cellpadding="0" width="50%">
							<tr>
								<td align="center">
									<form action="/isolated/UploadDriveImagePost.cfm" class="dropzone" id="dropzone">
										<input type="Hidden" name="Drive" value="#URL.Drive#">
									</form>
									<form action="/DispDrive.cfm" method="GET">
										<input type="Hidden" name="Drive" value="#Key#|#PortNo#">
										<input type="Submit" value="Cancel">
									</form>
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>
		</td>
	</tr>
</table>
</center>
</body>
</html>
</CFOUTPUT>
