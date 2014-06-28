App = Ember.Application.create()

App.Options =
  sample_count: 10
  sampling_interval_ms: 500
  broken_sensor_reading: 4095
  max_sensor_reading: 4095

App.Router.map ->
  @resource 'sensors', ->
    @route 'sensor', {path: '/:sensor_no'}

window.sensors = sensors = [
  Ember.Object.create
    id: 1
    desc: "Prechamber, ground"
    points: Ember.A()
,
  Ember.Object.create
    id: 2
    desc: "Prechamber, ground"
    points: Ember.A()
,
  Ember.Object.create
    id: 3
    desc: "Chamber, head"
    points: Ember.A()
,
  Ember.Object.create
    id: 4
    desc: "Chamber, groin"
    points: Ember.A()
,
  Ember.Object.create
    id: 5
    desc: "Chamber, ground"
    points: Ember.A()
,
  Ember.Object.create
    id: 6
    desc: "Chamber, ground"
    points: Ember.A()
,
  Ember.Object.create
    id: 7
    desc: "Unused"
    points: Ember.A()
]

points = [
  r: 115.54
  adc: 4015
,
  r: 109.73
  adc: 3807
,
  r: 90.19
  adc: 3044
,
  r: 60.25
  adc: 1960
,
  r: 24.94
  adc: 1069
]

for sensor_no in [0...7]
  for point in points
    sensors[sensor_no].points.pushObject(Ember.Object.create(point))

App.ApplicationRoute = Ember.Route.extend
	model: -> sensors

App.SensorsSensorRoute = Ember.Route.extend
	model: (params) ->
    found = sensors[params.sensor_no-1]
  
  setupController: (controller, model) ->
    controller.set 'model', model
    
Utils =
  pt100: (r) ->
    table = [18.49, 20.65, 22.80, 24.94, 27.08, 29.20, 31.32, 33.43, 35.53, 37.63, 39.71, 41.79, 43.87, 45.94, 48.00, 50.06, 52.11, 54.15, 56.19, 58.22, 60.25, 62.28, 64.30, 66.31, 68.33, 70.33, 72.33, 74.33, 76.33, 78.32, 80.31, 82.29, 84.27, 86.25, 88.22, 90.19, 92.16, 94.12, 96.09, 98.04, 100.0, 101.95, 103.9, 105.85, 107.79, 109.73, 111.67, 113.61, 115.54, 117.47, 119.4]
    
    if r > table[0]

      left = 800
      
      t = -200
      i = 0
      dt = 0

      while t < 250
        break if left < 0
        
        i += 1
        
        dt = 5
        dt = 50  if (t > 110)
        dt = 40  if (t == 110)
        
        t += dt
        
        if (r < table[i])
          return t + (r - table[i]) * dt / (table[i+1] - table[i])
        
        #console.log left, t, i
        left -= 1
      
      return t

    
plot = null
    
plotFlot = (sensor_no) ->
  data = _.map(sensors[sensor_no-1].points, (point) -> [parseInt(point.adc), Utils.pt100(point.r)])
  linear_regression = ss.linear_regression().data(data)
  line = linear_regression.line()
  regression_data = [[0, line(0)], [4095, line(4095)]]
  equation = {m: linear_regression.m(), b: linear_regression.b()}

  if plot
    plot.setData([
      label: "&nbsp;Given points"
      data: data
      lines: {show: false}, points: {show: true}
    ,
      label: "&nbsp;Estimation"
      data: regression_data
      lines: {show: true}, points: {show: false}
    ])
    plot.setupGrid()
    plot.draw()
    
    $("#equation").html "<p class=\"lead\"><var>t</var> = #{equation.m.toFixed(6)} <var>r<sub>adc</sub></var> #{equation.b.toFixed(0).replace('-', '- ')} [℃]</p>"
          
refreshDegrees = (sensor_no) ->
  for point in sensors[sensor_no-1].points
    point.set('deg', Utils.pt100(point.r).toFixed(1))
      
App.SensorsSensorView = Ember.View.extend
  modelObserver: ( ->
    sensor = @get('controller.model')
    plotFlot(sensor.id)
    refreshDegrees(sensor.id)
  ).observes('controller.model')
    
 	didInsertElement: ->
    this._super()
    sensor_no = @get('controller.model').id    
    
    plot = $.plot("#plot", [],
      grid: {borderWidth: 1},
      legend: {position: "nw"},
      xaxis: {min: 0, max: 4100},
      yaxis: {min: -200, max: 50}
		)
    
    plotFlot(sensor_no)
    refreshDegrees(sensor_no)

App.FlotParamComponent = Ember.TextField.extend
  changeHandler: ( ->
    plotFlot(@get 'sensor_no')
    refreshDegrees(@get 'sensor_no')
  ).on('change')

read_back = {raw: [[], [], [], [], [], [], []], translated: [[], [], [], [], [], [], []]}

updateReadings = ->
  $.get "/adc", (readings_json) ->
    readings = JSON.parse readings_json
    for sensor_no in [0...7]
      if readings.raw[sensor_no] == App.Options.broken_sensor_reading
        read_back.raw[sensor_no] = []
        read_back.translated[sensor_no] = []
        sensors[sensor_no].set 'raw_reading', '-'
        sensors[sensor_no].set 'reading', ''
        sensors[sensor_no].set 'down', true
      else
        read_back.raw[sensor_no].push(readings.raw[sensor_no])
        read_back.translated[sensor_no].push(readings.translated[sensor_no])
        
        read_back.raw[sensor_no].shift()  if read_back.raw[sensor_no].length > App.Options.sample_count
        read_back.translated[sensor_no].shift()  if read_back.translated[sensor_no].length > App.Options.samle_count
        
        average = ss.mean(read_back.translated[sensor_no])
        raw_average = ss.mean(read_back.raw[sensor_no])
        
        stdev = ss.standard_deviation(read_back.translated[sensor_no])
        raw_stdev = ss.standard_deviation(read_back.raw[sensor_no])
        
        sensors[sensor_no].set 'average', average.toFixed(0)
        sensors[sensor_no].set 'stdev', stdev.toFixed(1)
        
        sensors[sensor_no].set 'raw_average', raw_average.toFixed(0)
        sensors[sensor_no].set 'raw_accuracy', (raw_stdev * 100 / App.Options.max_sensor_reading).toFixed(1)
        
        sensors[sensor_no].set 'down', false

setInterval updateReadings, App.Options.sampling_interval_ms
