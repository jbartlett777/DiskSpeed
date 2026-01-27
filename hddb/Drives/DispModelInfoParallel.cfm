<CFIF TestID.RecordCount LT 50>
	<CFSET Alpha=0.5>
<CFELSEIF TestID.RecordCount LT 75>
	<CFSET Alpha=0.3>
<CFELSEIF TestID.RecordCount LT 100>
	<CFSET Alpha=0.25>
<CFELSEIF TestID.RecordCount LT 150>
	<CFSET Alpha=0.15>
<CFELSE>
	<CFSET Alpha=0.05>
</CFIF>

<CFSAVECONTENT variable="JSHold">
<CFOUTPUT>
<script>
// Graph #GraphID#
var el = document.getElementById('Graph#GraphID#');
var data = {
	categories: [#Categories#],
	series: [
		#Series#
	]
};
var options = {
	chart: {
		title: {
			text: '#GraphTitle#',
			align: 'center'
		},
		animation: false,
	//	width: 'auto',
	//	height: 'auto'
	},
	yAxis: {
		label: {
			formatter: (value) => {
				var MB=value / 1000000;
				return `${MB} MB/Sec`;
			}
		}
	},
	series: {
		spline: true,
	},
	legend: {
		visible: false
	},
	theme: {
		series: {
			colors: ['##0bc8c8#SeriesAlpha#'],
		},
		chart: {
			backgroundColor: '##00000000'
		},
		title: {
			fontFamily: 'sans-serif',
			color: '##ffffff'
		},
		xAxis: {
			title: {
				fontFamily: 'sans-serif',
				fontSize: 15,
				fontWeight: 400,
				color: '##ffffff'
			},
			label: {
				fontFamily: 'sans-serif',
				fontSize: 11,
				fontWeight: 700,
				color: '##ffffff'
			},
			width: 2,
			color: '##ffffff'
		},
		yAxis: {
			title: {
				fontFamily: 'sans-serif',
				fontSize: 15,
				fontWeight: 400,
				color: '##ffffff'
			},
			label: {
				fontFamily: 'sans-serif',
				fontSize: 11,
				fontWeight: 700,
				color: '##ffffff'
			},
			width: 2,
			color: '##ffffff'
		}
	}
};

var chart#GraphID# = toastui.Chart.lineChart({ el, data, options });
    
</script>

</CFOUTPUT>
</CFSAVECONTENT>
<CFSET JS=JS & JSHold>
