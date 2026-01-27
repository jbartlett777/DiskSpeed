<CFOUTPUT>
<div id="heatmap#GraphID#" style="min-width: 800px; max-width: 800px; height: 400px; margin: 0 auto;" class="FloatLeft"></div>
<script type="text/javascript">
var chart#GraphID# = Highcharts.chart('heatmap#GraphID#',{
	chart: {
		type: 'heatmap',
		backgroundColor: 'rgba(255, 255, 255, 0.0)',
		plotBorderColor: '##606063'
	},
	title: {
		text: '#GraphTitle#',
		style: {
			color: '##E0E0E3'
		}
	},
	subtitle: {
			text: '#GraphSubTitle#',
		style: {
			color: '##E0E0E3'
		}
	},
	credits: {
		"enabled": false
	},
	legend: {
		"enabled": false
	},
	boost: {
		seriesThreshold: 1,
		useGPUTranslations: true
	},
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
		type: 'number',
		visible: false
	},
	tooltip: {
        enabled: false
    },
	//tooltip: {
	//	formatter: function() {
	//		if (this.point.options.b===1) return this.point.options.l + ': Bad Block';
	//		if (this.point.value===null) return false;
	//		return this.point.options.l + ': ' + this.point.value + 'MB/s';
	//	}
	//},
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
		min: 0,
		max: #MaxSpot#,
		startOnTick: false,
		endOnTick: false,
		tickInterval: 0,
		stops: [
			[0, "##000000"],
			[0.75, "##707070"],
			[1, "##ffffff"]
		]
	},
	series: [{
		turboThreshold: 0,
		boostThreshold: 100,
		borderWidth: 0,
		nullColor: "##000000",
		data: [#HeatData#]
	}]
});
</script>
</CFOUTPUT>