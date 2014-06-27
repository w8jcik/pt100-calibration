App = Ember.Application.create()
App.Router.map ->
  @resource 'sensors', ->
    @route 'sensor', {path: '/:sensor_no'}

window.sensors = sensors = [
  id: 1
  desc: "Prechamber, ground"
  points: [
  	r: 115.54
  	adc: 4015
  	deg: undefined
 	,
  	r: 109.73
  	adc: 3807
  	deg: undefined
 	,
  	r: 90.19
  	adc: 3044
  	deg: undefined
 	,
  	r: 60.25
  	adc: 1960
  	deg: undefined
 	,
  	r: 24.94
  	adc: 1069
  	deg: undefined
  ]
,
  id: 2
  desc: "Prechamber, ground"
,
  id: 3
  desc: "Chamber, head"  
,
  id: 4
  desc: "Chamber, groin"  
,
  id: 5
  desc: "Chamber, ground"  
,
  id: 6
  desc: "Chamber, ground"
,
  id: 7
  desc: "Unused"
]

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
        t += dt
        
        if (r < table[i])
          return t + (r - table[i-1]) * dt / (table[i] - table[i-1])
        
        #console.log left, t, i
        left -= 1
      
      return t

    
plot = null
    
plotFlot = (sensor_no) ->
  data = _.map(sensors[sensor_no-1].points, (point) -> [point.adc, Utils.pt100(point.r)])
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
    
    $("#equation").html "<p class=\"lead\"><var>y</var> = #{equation.m.toFixed(6)} <var>x</var> #{equation.b.toFixed(0)}</p>"
          
# AmbiantBox.AmbiantsController = Ember.ArrayController.extend({
#   myArray: Em.A(),
#   fillData: function(){
#       obj = Ember.Object.create({index: 0, status: 'hide'});
#       this.myArray.pushObject(obj);
#   },
# });
      
App.SensorsSensorView = Ember.View.extend
  modelObserver: ( ->
    Ember.run.scheduleOnce 'afterRender', this, () ->
      sensor = @get('controller.model')
      if sensor.points
      	for point in sensor.points
        	console.log point
      plotFlot(sensor.id)
  ).observes('controller.model')
    
 	didInsertElement: ->
    this._super()
    sensor_no = @get('controller.model').id    
    plotFlot(sensor_no)
    
    plot = $.plot("#plot", [],
      grid: {borderWidth: 1},
      legend: {position: "nw"},
      xaxis: {min: 0, max: 4100},
      yaxis: {min: -200, max: 50}
		)

App.FlotParamComponent = Ember.TextField.extend
  changeHandler: ( ->
    plotFlot(@get 'sensor_no')
  ).on('change')
