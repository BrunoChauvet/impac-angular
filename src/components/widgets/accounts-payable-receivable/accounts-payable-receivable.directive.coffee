module = angular.module('impac.components.widgets.accounts-payable-receivable',[])

module.controller('WidgetAccountsPayableReceivableCtrl', ($scope, $q, ChartFormatterSvc) ->

  w = $scope.widget

  # Define settings
  # --------------------------------------
  $scope.orgDeferred = $q.defer()
  $scope.timeRangeDeferred = $q.defer()
  $scope.histModeDeferred = $q.defer()
  $scope.chartDeferred = $q.defer()

  settingsPromises = [
    $scope.orgDeferred.promise
    $scope.timeRangeDeferred.promise
    $scope.histModeDeferred.promise
    $scope.chartDeferred.promise
  ]


  # Widget specific methods
  # --------------------------------------
  w.initContext = ->
    $scope.isDataFound = w.content? && w.content.values?

  $scope.getCurrentPayable = ->
    _.last(w.content.values.payables) if $scope.isDataFound

  $scope.getCurrentReceivable = ->
    _.last(w.content.values.receivables) if $scope.isDataFound

  $scope.getCurrency = ->
    w.content.currency if $scope.isDataFound


  # Chart formating function
  # --------------------------------------
  $scope.drawTrigger = $q.defer()
  w.format = ->
    if $scope.isDataFound
      lineData = [
        {title: "Payable", labels: w.content.dates, values: w.content.values.payables },
        {title: "Receivable", labels: w.content.dates, values: w.content.values.receivables },
      ]

      all_values_are_positive = true
      for value in w.content.values.payables
        all_values_are_positive &&= value >= 0
      for value in w.content.values.receivables
        all_values_are_positive &&= value >= 0

      lineOptions = {
        scaleBeginAtZero: all_values_are_positive,
        showXLabels: false,
      }
      chartData = ChartFormatterSvc.lineChart(lineData,lineOptions, true)
      
      # calls chart.draw()
      $scope.drawTrigger.notify(chartData)


  # Widget is ready: can trigger the "wait for settigns to be ready"
  # --------------------------------------
  $scope.widgetDeferred.resolve(settingsPromises)
)

module.directive('widgetAccountsPayableReceivable', ->
  return {
    restrict: 'A',
    controller: 'WidgetAccountsPayableReceivableCtrl'
  }
)