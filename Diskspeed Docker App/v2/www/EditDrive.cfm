<CFPARAM name="URL.AutoSubmit" default="">

<CFIF FileExists("#PersistDir#/storage.json") AND FileExists("#PersistDir#/hwtree.json")>
	<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
	<CFSET HW=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/storageref.json" variable="json">
	<CFSET Ref=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/hwtree.json" variable="json">
	<CFSET HWTree=DeserializeJSON(json)>
	<CFFILE action="read" file="#PersistDir#/usbtree.json" variable="json">
	<CFSET USBTree=DeserializeJSON(json)>
<CFELSE>
	<CFABORT>
</CFIF>

<CFINCLUDE TEMPLATE="Styles.cfm">
<CFFILE action="read" file="#SaveDir#/drives.css" variable="DriveCSS">

<CFSET Key=ListFirst(URL.Drive,"|")>
<CFSET PortNo=ListLast(URL.Drive,"|")>
<CFSET Drive=HW[Key].Ports[PortNo].Config>
<CFSET Drive.ImageWidth=128>
<CFSET Drive.ImageHeight=190>
<CFSET DriveKey="#Key#|#PortNo#">
<CFSET Drive.TextXPer=Int(Drive.TextX / Drive.ImageWidth / 0.01) + 1>
<CFSET Drive.TextYPer=Int(Drive.TextY / Drive.ImageHeight / 0.01) + 1>
<CFIF Drive.TextRotation NEQ 0>
	<CFSET x=Drive.TextXPer>
	<CFSET y=Drive.TextYPer>
	<CFSET Drive.TextXPer=y>
	<CFSET Drive.TextYPer=100 - x>
</CFIF>
<CFIF Left(Drive.FontColor,1) NEQ Chr(35)>
	<CFSET Drive.FontColor=Chr(35) & Drive.FontColor> <!--- Add leading pound sign if not given --->
</CFIF>

<CFOUTPUT>
<style type="text/css">
#DriveCSS#
.Slider1 {position:relative;top:0px;left:0px;z-index:99;width:#Drive.ImageHeight#px; height:20px; margin:0; transform-origin:#Int(Drive.ImageHeight/2)#px #Int(Drive.ImageHeight/2)#px;border-top-width:0px;border-top-style:solid;padding-top:0px;padding-bottom:0px;z-index:1;-webkit-transform: rotate(-90deg);-moz-transform: rotate(-90deg);-ms-transform: rotate(-90deg);-o-transform: rotate(-90deg);filter: progid:DXImageTransform.Microsoft.BasicImage(rotation=3);}
.Slider2 {width:#Drive.ImageHeight#px; height:20px; margin:0; transform-origin:#Int(Drive.ImageHeight/2)#px #Int(Drive.ImageHeight/2)#px;border-top-width:0px;border-top-style:solid;padding-top:0px;padding-bottom:0px;z-index:1;-webkit-transform: rotate(90deg);-moz-transform: rotate(90deg);-ms-transform: rotate(90deg);-o-transform: rotate(90deg);filter: progid:DXImageTransform.Microsoft.BasicImage(rotation=1);}
</style>
<CFIF URL.AutoSubmit EQ "Y">
	<body onLoad="AutoSubmit()">
<CFELSE>
	<body>
</CFIF>
<script src='/includes/spectrum.js'></script>
<link rel='stylesheet' href='/includes/spectrum.css' />
<script language="JavaScript">
//parent.document.getElementById('DriveButton').innerHTML='<a href="javascript:void(0)" data-fancybox data-type="iframe" data-src="/isolated/UploadDriveImage.cfm?Drive=#URLEncodedFormat(DriveKey)#">xxx</a>';
</script>
<CFSET FormID=RandRange(0,9999999)>
<CFIF URL.AutoSubmit EQ "Y">
	<form action="EditDrivePost.cfm" id="Edit_#FormID#" method="post" enctype="multipart/form-data">
<CFELSE>
	<form action="EditDrivePost.cfm" id="Edit_#FormID#" method="post" enctype="multipart/form-data" target="_parent">
</CFIF>
<input type="Hidden" name="Key" value="#Key#">
<input type="Hidden" name="PortNo" value="#PortNo#">
<input type="Hidden" name="AutoSubmit" value="#URL.AutoSubmit#">
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td>
			<div style="display:inline-block; width:20px; height:#Drive.ImageHeight#px; padding:0;">
				<input name="PosY" id="PosY" type="range" min="1" max="100" step="1" value="#Drive.TextYPer#" data-orientation="vertical" class="Slider1">
			</div>
		</td>
		<td id="ImgTextContainer" style="background-image:url('images/inuse/#CurrInstance#/#Drive.SaveDir#.png?random=#Drive.Random#');background-repeat:no-repeat;background-position:center;">
			<div id="ImgText">#HW[Key].Ports[PortNo].Attrib.Size.DispSize#</div>
		</td>
	</tr>
	<tr>
		<td></td>
		<td><input name="PosX" id="PosX" type="range" min="1" max="100" step="1" value="#Drive.TextXPer#" data-orientation="horizontalcal" style="width:#Drive.ImageWidth#px;margin-left:0px;margin-right:0px;padding-left:0px;border-left-width:0px;padding-right:0px;z-index:1;"></td>
	</tr>
	<tr>
		<td colspan="2" align="right">
			<!--- <button type="button" onclick="parent.document.getElementById('DriveButton').click()">Upload New Image</button> --->
			<button type="button" onclick="location.href='/isolated/UploadDriveImage.cfm?Drive=#URLEncodedFormat(DriveKey)#'" type="Button">Upload New Image</button>
		</td>
	</tr>
</table>

<a href="#StrangeJourney#/hddb.cfm?View=images&Vendor=#HW[Key].Ports[PortNo].Attrib.Vendor#" class="Arial Size12 Black" target="_blank">Search for #HW[Key].Ports[PortNo].Attrib.Vendor# drive images</a><br>
<br>
<input type="checkbox" name="TextOverlay" id="TextOverlay" value="1" onChange="UpdateTextOverlay()"<CFIF Drive.TextOverlay> CHECKED</CFIF>>&nbsp;Overlay Drive Capacity<br>
Font: <select name="TextFont" id="TextFont" size="1" onChange="UpdateCSS()">
<CFLOOP index="Font" list="Arial,Arial Black,Courier New,Garamond,Georgia,Helvetica,Impact,Times New Roman,Verdana"><!---Google Font--->
	<option value="#Font#"<CFIF Drive.TextFont EQ Font> SELECTED</CFIF>>#Font#</option>
</CFLOOP>
</select>
<input type="checkbox" name="TextBold" id="TextBold" value="1"<CFIF Drive.TextBold> CHECKED</CFIF> onChange="UpdateTextSize();UpdateCSS()">&nbsp;Bold
<input type="checkbox" name="TextItalics" id="TextItalics" value="1"<CFIF Drive.TextItalics> CHECKED</CFIF> onChange="UpdateTextSize();UpdateCSS()">&nbsp;Italic
<input type="text" name="TextColor" id="TextColor" value="#Drive.FontColor#" size="1" onChange="UpdateCSS()">
<!--- <input type="text" name="GoogleFont" value="#Drive.GoogleFont#" size="30"> --->
<br>
<input type="checkbox" name="CenterX" id="CenterX"<CFIF Drive.CenterX> CHECKED</CFIF> value="1" onChange="ToggleCenterX()">&nbsp;Center Horizontally<br>
<input type="checkbox" name="CenterY" id="CenterY"<CFIF Drive.CenterY> CHECKED</CFIF> value="1" onChange="ToggleCenterY()">&nbsp;Center Vertically<br>
<input type="checkbox" name="TextRotation" id="TextRotation" value="90"<CFIF Drive.TextRotation NEQ 0> CHECKED</CFIF>> Rotate Text<br>
<table border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td><input type="range" name="TextSize" id="TextSize" value="#Drive.FontSize#" min="10" max="50" step="1" style="margin-left:0px;margin-right:0px;padding-left:0px;border-left-width:0px;padding-right:0px;"></td>
		<td valign="middle">&nbsp;Text Size</td>
	</tr>
</table>
<!---<input type="range" name="TextRotation" id="TextRotation" value="#Drive.TextRotation#" min="-180" max="180" step="90" onMouseDown="EnableDriveFrame(true)" onMouseUp="EnableDriveFrame(false)" style="margin-left:0px;margin-right:0px;padding-left:0px;border-left-width:0px;padding-right:0px;"> Text Rotation<br>--->
<CFTRY>
	<CFIF ListLen(Ref.Vendor[HW[Key].Ports[PortNo].Attrib.Vendor][HW[Key].Ports[PortNo].Attrib.Model]) GT 1>
		<input type="Checkbox" name="SyncModels" value="Y">&nbsp;Apply changes to all drives of the same model<br>
	</CFIF>
<CFCATCH Type="Any">
	<!--- Eat any unknown vendor --->
</CFCATCH>
</CFTRY>
<br>
<input type="Submit" value="Save Changes">&nbsp;&nbsp;
<CFIF HW[Key].Ports[PortNo].Config.DriveEdited>
	<input type="Submit" name="SubmitButton" value="Reset Image">&nbsp;&nbsp;
</CFIF>
<input type="Button" value="Cancel" onClick="document.location='DispDrive.cfm?Drive=#URLEncodedFormat(DriveKey)#'">&nbsp;&nbsp;
<!-- The section below needs to be technically visible for the Javascript to work but no reason to make it seem like something's there -->
<span class="DefaultCursor KindaHidden">
<br><br>
Text Loc: <input type="text" name="TextLocX" id="x" size="4" class="DefaultCursor">x<input type="text" name="TextLocY" id="y" size="4" class="DefaultCursor"><br>
Text Size: <input type="text" id="tx" size="4" class="DefaultCursor">x<input type="text" id="ty" size="4" class="DefaultCursor"><br>
Slider: <input type="text" id="sliderx" size="4" class="DefaultCursor">x<input type="text" id="slidery" size="4" class="DefaultCursor"><br>
CSS: <input type="text" id="newcss" name="newcss" size="100" class="DefaultCursor" OnKeyUp="ApplyCSS()"><br>
<table border="1" cellpadding="0" cellspacing="0" width="1" class="KindaHidden"><tr><td width="1"><div id="Capacity" style="font-size:20px;">#HW[Key].Ports[PortNo].Attrib.Size.DispSize#</div></td></tr></table>
Frame On: <input type="checkbox" id="fo" onChange="EnableDriveFrame()">
</span>
</form>
<script language="JavaScript">

var FrameOn=false;
var LastRotateStatus=document.getElementById('TextRotation').checked;
function AutoSubmit()
{
	document.getElementById('Edit_#FormID#').submit();
}
function EnableDriveFrame()
{
	FrameOn=document.getElementById('fo').checked;
	UpdateCSS();
}
function UpdateX()
{
	if (document.getElementById('TextRotation').checked == false)
	{
		document.getElementById('sliderx').value=document.getElementById('PosX').value;
		document.getElementById('x').value=Math.trunc(document.getElementById('PosX').value / 100 * #Drive.ImageWidth#);
	} else {
		document.getElementById('slidery').value=document.getElementById('PosX').value;
		document.getElementById('y').value=Math.trunc(document.getElementById('PosX').value / 100 * #Drive.ImageHeight#);
	}
	UpdateCSS();
}
function UpdateY()
{

	if (document.getElementById('TextRotation').checked == false)
	{
		document.getElementById('slidery').value=document.getElementById('PosY').value;
		document.getElementById('y').value=Math.trunc(document.getElementById('PosY').value / 100 * #Drive.ImageHeight#);
	} else {
		document.getElementById('sliderx').value=document.getElementById('PosY').value;
		document.getElementById('x').value=Math.trunc((100-document.getElementById('PosY').value) / 100 * #Drive.ImageWidth#);
	}
	UpdateCSS();
}
function ToggleCenterX()
{
	if (document.getElementById('CenterX').checked == true)
	{
		//document.getElementById('PosX').value=#Int(Drive.ImageWidth / 2)#;
		document.getElementById('PosX').value=50;
		UpdateX();
		document.getElementById('PosX').disabled=true;
	} else {
		document.getElementById('PosX').disabled=false;
	}
	UpdateCSS();
}
function ToggleCenterY()
{
	if (document.getElementById('CenterY').checked == true)
	{
		//document.getElementById('PosY').value=#Int(Drive.ImageHeight / 2)#;
		document.getElementById('PosY').value=50;
		UpdateY();
		document.getElementById('PosY').disabled=true;
	} else {
		document.getElementById('PosY').disabled=false;
	}
	UpdateCSS();
}
function UpdateTextDem()
{
	document.getElementById('tx').value=Math.round($('##Capacity').width());
	document.getElementById('ty').value=Math.round($('##Capacity').height());
}
function UpdateTextOverlay()
{
	if (document.getElementById('TextOverlay').checked == false)
	{
		document.getElementById('PosX').disabled=true;
		document.getElementById('PosY').disabled=true;
		document.getElementById('TextFont').disabled=true;
		document.getElementById('TextBold').disabled=true;
		document.getElementById('TextItalics').disabled=true;
		document.getElementById('TextColor').disabled=true;
		document.getElementById('CenterX').disabled=true;
		document.getElementById('CenterY').disabled=true;
		document.getElementById('TextSize').disabled=true;
		document.getElementById('TextRotation').disabled=true;
	} else {
		document.getElementById('PosX').disabled=false;
		document.getElementById('PosY').disabled=false;
		document.getElementById('TextFont').disabled=false;
		document.getElementById('TextBold').disabled=false;
		document.getElementById('TextItalics').disabled=false;
		document.getElementById('TextColor').disabled=false;
		document.getElementById('CenterX').disabled=false;
		document.getElementById('CenterY').disabled=false;
		document.getElementById('TextSize').disabled=false;
		document.getElementById('TextRotation').disabled=false;
	}
	$('##TextColor').spectrum({
	    color: '###Drive.FontColor#',
	    showInput: true,
	    clickoutFiresChange: true,
	    showInitial: true,
	    preferredFormat: "hex"
	});
	UpdateCSS();
}
function RotateXY()
{
	var HoldX=document.getElementById('PosX').value;
	var HoldY=document.getElementById('PosY').value;
	document.getElementById('PosX').value=HoldY;
	document.getElementById('PosY').value=HoldX;
	UpdateX();
	UpdateY();
	UpdateCSS();
}
function UpdateCSS()
{
	if (document.getElementById('TextOverlay').checked == false)
	{
		CSS='display:none;';
		document.getElementById('newcss').value=CSS;
		$(ImgText).attr('style', CSS);
		return true;
	}
	UpdateTextSize();
	UpdateTextDem();
	var CapWidth=Math.round($('##Capacity').width());
	var CapHeight=Math.round($('##Capacity').height());
	var Bold='';
	var Italic='';
	var IW=0;
	var IH=0;
	var FontSize=document.getElementById('TextSize').value + 'px ';
	if (document.getElementById('TextBold').checked == true) Bold='bold ';
	if (document.getElementById('TextItalics').checked == true) Italic='italic ';

	IW=#Drive.ImageWidth#;
	IH=#Drive.ImageHeight#;
	var px=document.getElementById('x').value - Math.round(CapWidth / 2);

	if (px < 0) px=0;
	var py=(IH - document.getElementById('y').value) - Math.round(CapHeight / 2);
	if (py < 0) py=0;

	if (px > IW - CapWidth) px=IW - CapWidth;
	if (py + CapHeight > IH) py=IH - CapHeight;

	var h=IH - py;
	var CSS='width:'+IW+'px;';
	CSS=CSS + 'font:' + Bold + Italic + FontSize + document.getElementById('TextFont').options[document.getElementById('TextFont').selectedIndex].text + ';';
	CSS=CSS + 'color:' + document.getElementById('TextColor').value + ';';
	CSS=CSS + 'text-indent:' + Math.trunc(px) + 'px;';
	CSS=CSS + 'padding-top:' + Math.trunc(py) + 'px;';
	CSS=CSS + 'height:' + Math.trunc(h) + 'px;';
	CSS=CSS + 'cursor:default;';
	if (document.getElementById('TextRotation').checked == true) CSS=CSS + '-webkit-transform:rotate(90deg);-moz-transform:rotate(90deg);-ms-transform:rotate(90deg);-o-transform:rotate(90deg);filter:progid:DXImageTransform.Microsoft.BasicImage(rotation=1);';
	document.getElementById('newcss').value=CSS;

	if (FrameOn == true) CSS=CSS + 'background-color:rgba(255,0,0,0.1);';

	$(ImgText).attr('style', CSS);
}
function ApplyCSS()
{
	$(ImgText).attr('style', document.getElementById('newcss').value);
}
function UpdateTextSize()
{
	document.getElementById('Capacity').style.fontSize=document.getElementById('TextSize').value + 'px';
	if (document.getElementById('TextBold').checked == true)
	{
		document.getElementById('Capacity').style.fontWeight='bold';
	} else {
		document.getElementById('Capacity').style.fontWeight='normal';
	}
	if (document.getElementById('TextItalics').checked == true)
	{
		document.getElementById('Capacity').style.fontStyle='italic';
	} else {
		document.getElementById('Capacity').style.fontStyle='normal';
	}
	//document.getElementById('Capacity').style.transform='rotate(' + document.getElementById('TextRotation').value + 'deg)';
	if (document.getElementById('TextRotation').checked == false)
	{
		document.getElementById('Capacity').style.transform='rotate(0deg)';
	} else {
		document.getElementById('Capacity').style.transform='rotate(90deg)';
	}
}
//color:black; font-size:30px; vertical-align:middle; text-align:center; line-height:175px;
//UpdateTextDem();
UpdateX();
UpdateY();
UpdateTextOverlay();
UpdateCSS();
ToggleCenterX();
ToggleCenterY();
document.getElementById('PosX').addEventListener('input', function() {UpdateX()}, false);
document.getElementById('PosY').addEventListener('input', function() {UpdateY()}, false);
document.getElementById('TextSize').addEventListener('input', function() {UpdateCSS()}, false);
document.getElementById('TextRotation').addEventListener('input', function() {RotateXY()}, false);
$('##TextColor').spectrum({
    color: '###Drive.FontColor#',
    showInput: true,
    clickoutFiresChange: true,
    showInitial: true,
    preferredFormat: "hex"
});
</script>
</body>
</html>
</CFOUTPUT>
