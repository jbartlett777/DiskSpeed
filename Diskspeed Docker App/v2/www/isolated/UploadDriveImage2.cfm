<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>

<CFSET Key=ListFirst(URL.Drive,"|")>
<CFSET PortNo=ListLast(URL.Drive,"|")>

<CFSET FN=HW[Key].Ports[PortNo].Config.SaveDir>
<CFFILE action="copy" source="#PersistDir#/driveinfo/#FN#/user.png" destination="#RootDir#/images/inuse/#CurrInstance#/#fn#_new.png">
<CFSET ImageData=ImageInfo(ImageRead("#RootDir#/images/inuse/#CurrInstance#/#fn#_new.png"))>

<CFSET ImgHeight=ImageData.Height>
<CFSET ImgWidth=ImageData.Width>

<CFSET MaxHeight=450>
<CFSET MaxWidth=310>

<!--- <CFOUTPUT>Original: #ImgWidth#x#ImgHeight#<br></CFOUTPUT> --->

<CFIF ImgHeight GT MaxHeight>
	<CFSET ImgWidth=Int(ImgWidth / ImgHeight * MaxHeight)>
	<CFSET ImgHeight=MaxHeight>
</CFIF>
<CFIF ImgWidth GT MaxWidth>
	<CFSET ImgHeight=Int(ImgHeight / ImgWidth * MaxWidth)>
	<CFSET ImgWidth=MaxWidth>
</CFIF>

<!--- <CFOUTPUT>Modified: #ImgWidth#x#ImgHeight#<br></CFOUTPUT> --->

<CFOUTPUT>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="x-ua-compatible" content="ie=edge">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<link rel="stylesheet" href="/includes/cropper.min.css">
<style>
html {height:100%;}
body {font-family:Arial, Helvetica, sans-serif;height:100%;margin: 0 auto;}
.Arial {font-family:Arial, Helvetica, sans-serif;}
.container {
	margin: 20px auto;
	height: #ImgHeight#px;
}
img {
	max-width: 100%;
}
.row,
.preview {
	overflow: hidden;
}
.col {
	float: left;
}
.col-6 {
	width: #ImgWidth#px;
	min-width: 500px;
	min-height: 400px;
	max-height: 450px;
}
.col-3 {
	width: 128px;
	min-width: 128px;
	max-width: 128px;
	height: 190px;
	min-height: 190px;
	max-height: 190px;
}
.col-4 {
	width: 10px;
}
.col-5 {
	width: 140px;
}
.Red {color:red;}
</style>
<script type="text/javascript" src="/includes/jquery-3.2.1.min.js"></script>
<script type="text/javascript" src="/includes/cropper.min.js"></script>

</head>
<body>
<big><b>Upload new image for #HW[Key].Ports[PortNo].Attrib.Vendor# #HW[Key].Ports[PortNo].Attrib.Model# (#HW[Key].Ports[PortNo].Attrib.Serial#)</b></big>
<center>
<table border="0" cellpadding="0" cellspacing="0" width="100%" height="97%">
	<tr>
		<td align="center" valign="middle">
			<table border="0" cellpadding="0" cellspacing="0">
				<tr>
					<td width="50">
						<img src="/images/rotate_right.png" width="50" height="50" onClick="rotate_image(90)"><br>
						<img src="/images/rotate_left.png" width="50" height="50" onClick="rotate_image(-90)"><br>
						<img src="/images/expand.png" width="50" height="50" onClick="expand_crop()">
					</td>
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td>
						<div class="container">
							<div class="row">
								<div class="col col-6">
									<img id="image" src="/images/inuse/#CurrInstance#/#fn#_new.png" alt="Picture">
								</div>
								<div class="col col-4">
									&nbsp;
								 </div>
								<div class="col col-3">
									<div class="preview"></div>
								</div>
							</div>
						</div>
					</td>
					<td>&nbsp;&nbsp;&nbsp;</td>
					<td valign="top" class="Arial">
						This is how your cropped image will look.<br>
						<br>
						Adjust the frame over your uploaded image
						until it is flushed with the edges of the
						drive.<br>
						<br>
						Text should be readable top-down but if
						the portrait version of the drive has the
						words facing to the side, rotate the image
						until the words are reading top-down from
						right-left - ie: bottom of the words facing
						the left side of the monitor.<br>
						<br>
						<span class="Red">Note:</span> If you get timeout errors on saving
						the image, you went overboard on the size
						and will have to choose another image or
						resize it down to maybe 1,000 pixels high.<br>
						<br>
						<table border="0" cellpadding="0" cellspacing="0">
							<tr>
								<td><button id="btnCrop">Save</button></td>
								<td>&nbsp;&nbsp;&nbsp;</td>
								<td>
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
<form action="UpdateDriveImage2Post.cfm" id="SaveImageForm" method="POST">
<input type="hidden" name="Drive" value="#URL.Drive#">
<input type="Hidden" name="ImgData" id="ImgData" value="">
</form>

<script >
$(function() {
  var $image = $('##image'),
      height = $image.height() + 4;

  $('.preview').css({
	 width: '100%',
	 overflow: 'hidden',
	 height:    '#ImgHeight#px',
	 maxWidth:  '128px',
	 maxHeight: '183px'
   });

  $image.cropper({
  	  zoomable: false,
	  preview: '.preview',
	  ready: function (e) {
		 $(this).cropper('setData', {
			rotate: 0,
			rotatable: true
		 });
	  }
  });
});

var ImgWidth=#ImageData.Width#;
var ImgHeight=#ImageData.Height#;
function rotate_image(d)
{
	var $image = $('##image');
	$image.cropper('rotate', d)
	var w=ImgWidth;
	var h=ImgHeight;
	ImgWidth=h;
	ImgHeight=w;
}

function expand_crop()
{
	var $image = $('##image');
	$image.cropper("setData", {'x':0,'y':0,'width':ImgWidth,'height':ImgHeight})
}


$('##btnCrop').click(function() {
  // Get a string base 64 data url
  document.getElementById('btnCrop').innerHTML='Saving...';
  document.getElementById('btnCrop').disabled=true;
  var $image = $('##image')
  var croppedImageDataURL = $image.cropper('getCroppedCanvas').toDataURL("image/png");
  document.getElementById('ImgData').value=croppedImageDataURL;
  document.getElementById('SaveImageForm').submit();
});
</script>

</body>
</html>
</CFOUTPUT>


