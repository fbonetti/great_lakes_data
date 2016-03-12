var startElmApp = function(elmData) {
  var div = document.getElementById('container');
  var app = Elm.embed(Elm.Main, div, elmData);
  var chart = createChart();

  app.ports.data.subscribe(function(data) {
    chart.series[0].setData(data);
  });

  var timestampToDateString = function(date) {
    var year = date.getFullYear();
    var month = date.getMonth() + 1;
    var day = date.getDate();

    if (month < 10) {
      month = "0" + month;
    }

    if (day < 10) {
      day = "0" + day;
    }

    return [year, month, day].join("-");
  };

  var startDatePicker = $("#startDatePicker").datepicker({
    autoclose: true,
    format: "yyyy-mm-dd"
  });

  startDatePicker.on("changeDate", function(event) {
    var date = timestampToDateString(event.date);
    app.ports.startDate.send(date);
  });

  var endDatePicker = $("#endDatePicker").datepicker({
    autoclose: true,
    format: "yyyy-mm-dd"
  });

  endDatePicker.on("changeDate", function(event) {
    var date = timestampToDateString(event.date);
    app.ports.endDate.send(date);
  });
};

var createChart = function() {
  return new Highcharts.Chart({
    chart: {
      zoomType: 'x',
      renderTo: 'chart'
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
        marker: {
          radius: 2
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
  });
};
