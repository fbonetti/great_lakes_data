var startElmApp = function(elmData) {
  var div = document.getElementById('container');
  var app = Elm.embed(Elm.Main, div, elmData);
  var dailyAverageChart = initDailyAverageChart();
  var windRoseChart = initWindRoseChart();

  app.ports.dailyAverageData.subscribe(function(data) {
    dailyAverageChart.series[0].setData(data);
  });

  app.ports.windRoseData.subscribe(function(data) {
    windRoseChart.series[0].setData(data[0]);
    windRoseChart.series[1].setData(data[1]);
    windRoseChart.series[2].setData(data[2]);
    windRoseChart.series[3].setData(data[3]);
    windRoseChart.series[4].setData(data[4]);
    windRoseChart.series[5].setData(data[5]);
  });
};

var initDailyAverageChart = function() {
  return $("#dailyAverageChart").highcharts({
    chart: {
      zoomType: 'x'
    },
    title: {
      text: 'Daily average wind speed (knots)'
    },
    tooltip: {
      formatter: function() {
        return (
          '<span style="font-size:10px">' + Highcharts.dateFormat("%A, %b %e, %Y", this.x) + '</span>'
          + '<br/>'
          + Highcharts.numberFormat(this.y, 2)
          + ' knots'
        );
      }
    },
    xAxis: {
      type: 'datetime'
    },
    yAxis: {
      title: {
        text: 'Wind speed (knots)'
      },
      max: 30
    },
    legend: {
      enabled: false
    },
    plotOptions: {
      area: {
        fillColor: {
          linearGradient: {
            x1: 0,
            y1: 0,
            x2: 0,
            y2: 1
          },
          stops: [
            [0, Highcharts.getOptions().colors[0]],
            [1, Highcharts.Color(Highcharts.getOptions().colors[0]).setOpacity(0).get('rgba')]
          ]
        },
        lineWidth: 1,
        states: {
          hover: {
            lineWidth: 1
          }
        },
        threshold: null
      }
    },

    series: [{
      type: 'area',
      name: 'Wind speed',
      data: []
    }]
  }).highcharts();
};

var initWindRoseChart = function() {
  return $('#windRoseChart').highcharts({
    chart: {
      renderTo: 'windRoseChart'
    },
    series: [
      { name: '< 5', data: [] },
      { name: '5 - 10', data: [] },
      { name: '10 - 15', data: [] },
      { name: '15 - 20', data: [] },
      { name: '20 - 25', data: [] },
      { name: '> 25', data: [] },
    ],

    chart: {
      polar: true,
      type: 'column'
    },

    title: {
      text: 'Wind rose'
    },

    legend: {
      align: 'right',
      verticalAlign: 'top',
      y: 100,
      layout: 'vertical'
    },

    xAxis: {
      tickmarkPlacement: 'on',
      categories: [
       'N',
       'NNE',
       'NE',
       'ENE',
       'E',
       'ESE',
       'SE',
       'SSE',
       'S',
       'SSW',
       'SW',
       'WSW',
       'W',
       'WNW',
       'NW',
       'NNW'
      ]
    },

    yAxis: {
      min: 0,
      endOnTick: false,
      showLastLabel: true,
      title: {
        text: 'Frequency (%)'
      },
      labels: {
        formatter: function () {
          return this.value + '%';
        }
      },
      reversedStacks: false
    },

    tooltip: {
      valueSuffix: '%'
    },

    plotOptions: {
      series: {
        stacking: 'normal',
        shadow: false,
        groupPadding: 0,
        pointPlacement: 'on'
      }
    }
  }).highcharts();
};