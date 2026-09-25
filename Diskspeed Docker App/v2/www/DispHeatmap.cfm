<CFPARAM name="variables.BigGraph" default="1">

<CFSET Legend="Read Speed (MB/s)">
<CFIF FileExists("#HeatDir#/BadBlocks.txt")>
	<CFSET Legend=Legend & " - Bad Blocks Found">
</CFIF>

<CFOUTPUT>
<div id="Info" class="Arial Size 14 Black">&nbsp;</div>
<CFIF BigGraph EQ 0>
	<div id="heatmap" style="min-width: 310px; max-width: 800px; height: 400px; margin: 0 auto;"></div><div class="BR" />
<CFELSE>
	<div id="heatmap" style="mwidth: 90%; height: 60%; margin: 0 auto;"></div><div class="BR" />
</CFIF>
<script>
var chart = Highcharts.chart('heatmap',{
	chart: {
		type: 'heatmap'
	},
	title: {
		text: 'Speed Heatmap'
	},
	credits: {
		"enabled": false
	},
	legend: {
		title: {
			text: '#Legend#'
		},
		margin: 0
	},
	//boost: {
	//	seriesThreshold: 1,
	//	useGPUTranslations: true
	//},
	xAxis: {
		title: {
			text: null
		},
		type: 'number',
		showLastLabel: true,
		visible: false
	},
	yAxis: {
		title: {
			text: null
		},
		reversed: true,
		visible: false
	},
	tooltip: {
		formatter: function() {
			if (this.point.options.b===1) return this.point.options.l + ': Bad Block';
			if (this.point.value===null) return false;
			return this.point.options.l + ': ' + this.point.value + 'MB/s';
		}
	},
	noData: {
		style: {
			fontWeight: 'bold',
			fontSize: '20px',
			color: '##303030'
		}
	},
	lang: {
		noData: "There is no data to display yet, please wait..."
	},
	colorAxis: {
		min: #MinSpeed#,
		max: #MaxSpeed#,
		startOnTick: false,
		endOnTick: false,
		tickInterval: 0,
		stops: [
			[0, "##e31e1e"],
			[0.5, "##ffa500"],
			[0.9, "##1ae21a"]
		]
	},
	series: [{
		turboThreshold: 0,
		boostThreshold: 100,
		borderWidth: 0,
		nullColor: "##ffffff",
		data: [#HeatMapJSON#]
	}]
});
</script>
</CFOUTPUT>