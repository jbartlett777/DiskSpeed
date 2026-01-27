<CFOUTPUT>
<!DOCTYPE html>
<html>
<head>
<title>HDDB - Hard Drive Database</title>
<meta property="og:title" content="Hard Drive Database" />
<meta property="og:image" content="http://strangejourney.net/hddb/images/OGPreview.png" />
<meta property="og:url" content="http://strangejourney.net/hddb/index.cfm" />
<meta property="og:description" content="Hard Drive benchmark scores and heat maps" />
<script type="text/javascript" src="#Highcharts#/code/highcharts.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/export-data.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/heatmap.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/exporting.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/data.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/boost-canvas.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/boost.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/accessibility.js"></script>
<script type="text/javascript" src="#Highcharts#/code/modules/parallel-coordinates.js"></script>
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-FXL37075H7"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-FXL37075H7');
</script>
<style>
body {
	background-image: url("images/hddb_banner.png");
	background-repeat: no-repeat;
	background-position: top;
	background-color: ##1c1a1b;
	color:white;
}
.Arial {font-family:Arial, Helvetica, sans-serif;}
.Bold {font-weight:bold;}
.Size5 {font-size:5px;}
.Size12 {font-size:12px;}
.Size14 {font-size:14px;}
.Size18 {font-size:18px;}
.Size24 {font-size:24px;}
.Size40 {font-size:40px;}
.Size90 {font-size:90px;}
.Black {color:black;}
.Grey {color:##999;}
.LightGrey {color:##DDD;}
.Yellow {color:yellow;}
.Green {color:green;}
.White {color:white;}
.Red {color:red;}
.BR {clear:left;}
.NoLink {text-decoration:none;}
.Underline {text-decoration:underline;}
.NOBR {white-space:nowrap;}
.Center {text-align:center;}
.Right {text-align:right;}
.FloatLeft {float:left;}
.Margin10 {margin:10px;}
.Margin20 {margin:20px;}
.ImgBox {min-height:236px;}
.CursorPointer {cursor:pointer;}
.Columns {-moz-column-width:160px;-webkit-column-width:160px;column-width:160px;}
.Hidden {display:none;}
.TextBorder {text-shadow: rgb(0, 0, 0) 3px 0px 0px, rgb(0, 0, 0) 2.83333px 0.983333px 0px, rgb(0, 0, 0) 2.35px 1.85px 0px, rgb(0, 0, 0) 1.61667px 2.51667px 0px, rgb(0, 0, 0) 0.7px 2.91667px 0px, rgb(0, 0, 0) -0.283333px 2.98333px 0px, rgb(0, 0, 0) -1.25px 2.73333px 0px, rgb(0, 0, 0) -2.06667px 2.16667px 0px, rgb(0, 0, 0) -2.66667px 1.36667px 0px, rgb(0, 0, 0) -2.96667px 0.416667px 0px, rgb(0, 0, 0) -2.95px -0.566667px 0px, rgb(0, 0, 0) -2.6px -1.5px 0px, rgb(0, 0, 0) -1.96667px -2.26667px 0px, rgb(0, 0, 0) -1.11667px -2.78333px 0px, rgb(0, 0, 0) -0.133333px -3px 0px, rgb(0, 0, 0) 0.85px -2.88333px 0px, rgb(0, 0, 0) 1.75px -2.43333px 0px, rgb(0, 0, 0) 2.45px -1.73333px 0px, rgb(0, 0, 0) 2.88333px -0.833333px 0px;}
.button {
  background-color: blue;
  -webkit-border-radius: 10px;
  border-radius: 10px;
  border: none;
  color: ##FFFFFF;
  cursor: pointer;
  display: inline-block;
  font-family: Arial;
  font-size: 20px;
  padding: 5px 10px;
  text-align: center;
  text-decoration: none;
}
@-webkit-keyframes glowing {
  0% { background-color: blue; -webkit-box-shadow: 0 0 3px blue; }
  50% { background-color: blue; -webkit-box-shadow: 0 0 10px blue; }
  100% { background-color: blue; -webkit-box-shadow: 0 0 3px blue; }
}

@-moz-keyframes glowing {
  0% { background-color: blue; -moz-box-shadow: 0 0 3px blue; }
  50% { background-color: blue; -moz-box-shadow: 0 0 10px blue; }
  100% { background-color: blue; -moz-box-shadow: 0 0 3px blue; }
}

@-o-keyframes glowing {
  0% { background-color: blue; box-shadow: 0 0 3px blue; }
  50% { background-color: blue; box-shadow: 0 0 10px blue; }
  100% { background-color: blue; box-shadow: 0 0 3px blue; }
}

@keyframes glowing {
  0% { background-color: blue; box-shadow: 0 0 3px blue; }
  50% { background-color: blue; box-shadow: 0 0 10px blue; }
  100% { background-color: blue; box-shadow: 0 0 3px blue; }
}

.button {
  -webkit-animation: glowing 3500ms infinite;
  -moz-animation: glowing 3500ms infinite;
  -o-animation: glowing 3500ms infinite;
  animation: glowing 3500ms infinite;
}
</style>
</head>
<body>
<span class="Arial Bold White TextBorder Size90 NOBR CursorPointer" onClick="location.href='index.cfm'">Hard Drive Database</span><br>
<a class="button" href="index.cfm?View=BrandImages">Brand Image Database</a>&nbsp;&nbsp;&nbsp;&nbsp;
<a class="button" href="index.cfm?View=Drives">Model Database</a>
<br><br>
</CFOUTPUT>
