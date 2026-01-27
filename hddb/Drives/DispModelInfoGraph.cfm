<CFOUTPUT>
<div id="graph#GraphID#" style="min-width: 800px; max-width: 800px; height: 400px; margin: 0 auto;" class="FloatLeft"></div>
<script type="text/javascript">
var Chart#GraphID#=Highcharts.chart('graph#GraphID#', {
	colors: ['##2b908f', '##90ee7e', '##f45b5b', '##7798BF', '##aaeeee', '##ff0066', '##eeaaee', '##55BF3B', '##DF5353', '##7798BF', '##aaeeee'],
	chart: {
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
	xAxis: {
		title: {
			text: '#xAxis#',
			style: {
				color: '##A0A0A3'
			}
		},
		min: 0,
		max: #MaxSize#,
		gridLineColor: '##B0B0B0',
		lineColor: '##B0B0B0',
		minorGridLineColor: '##909090',
		tickColor: '##909090'
	},
	yAxis: {
		title: {
			text: 'Speed',
			style: {
				color: '##A0A0A3'
			}
		},
        //labels: {
        //    format: '{value}B'
        //},
		min: 0,
		max: #MaxY#,
		gridLineColor: '##B0B0B0',
		lineColor: '##B0B0B0',
		minorGridLineColor: '##909090',
		tickColor: '##909090'
	},
    plotOptions: {
        series: {
            marker: {
                enabled: false
            },
            animation: false,
            connectNulls: true
        }
    },
    tooltip: {
        formatter: function() {
        	var outx=Math.round(this.x / 1000000000);
        	var outy=(this.y / 1000000).toFixed(2);
            return outy + 'MB/sec at ' + outx + 'GB';
        }
    },
	legend: {
		enabled: false,
		itemStyle: {
			color: '##E0E0E3'
		},
		itemHoverStyle: {
			color: '##FFF'
		},
		itemHiddenStyle: {
			color: '##606063'
		}
	},
	credits: {
		enabled: false
	},
	lang: {
		nodata: 'No data to display yet'
	},
	series: [#Series#]
});
</script>
</CFOUTPUT>