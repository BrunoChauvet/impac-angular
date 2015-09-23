module = angular.module('impac.components.widget', [])

module.controller('ImpacWidgetCtrl', ($scope, $timeout, $log, DhbAnalyticsSvc, Utilities) ->

  # ---------------------------------------------------------
  # ### Widget template scope
  # ---------------------------------------------------------

  $scope.loaderImage = ''
  # TODO: add loader image options to impac-assets.svc
  # $scope.loaderImage = AssetPath['loader-white-bg.gif']

  # ---------------------------------------------------------
  # ### Toolbox
  # ---------------------------------------------------------

  # angular.merge doesn't exist in angular 1.2...
  extendDeep = (dst, src) ->
    angular.forEach src, (value, key) ->
      if dst[key] and dst[key].constructor and dst[key].constructor is Object
        extendDeep dst[key], value
      else
        dst[key] = value

  # ---------------------------------------------------------
  # ### Widget object management
  # ---------------------------------------------------------

  # Initialization
  w = $scope.widget || {}
  w.parentDashboard ||= $scope.parentDashboard
  w.settings = []
  w.isLoading = true
  w.hasEditAbility = true
  w.hasDeleteAbility = true

  # Retrieve the widget content from Impac! and initialize the widget from it.
  w.loadContent = (refreshCache=false) ->
    w.isLoading = true
    DhbAnalyticsSvc.widgets.show(w, refreshCache).then(
      (success) ->
        $log.debug('widget loadContent SUCCESS: ', success)
        updatedWidget = success.data
        updatedWidget.content ||= {}
        updatedWidget.originalName = updatedWidget.name
        angular.extend(w,updatedWidget)

        if $scope.isAccessibility
          w.initialWidth = w.width
          w.width = 12
        else if w.initialWidth 
          w.width = w.initialWidth

        # triggers the initialization of the widget's specific params (defined in the widget specific controller)
        w.initContext()
        # triggers the initialization of all the widget's settings
        w.initSettings()
        # formats the widget's chart data when needed
        w.isLoading = false
        w.format() if angular.isDefined(w.format)

      ,(errors) ->
        w.errors = Utilities.processRailsError(errors)
        w.isLoading = false
    )

  # Initialize all the settings of the widget
  w.initSettings = ->
    angular.forEach(w.settings, (setting) ->
      setting.initialize()
    )
    # TODO: following is still true ?
    # For discreet metadata updates, we don't want to force editMode to be false example: changing hist mode
    w.isEditMode = false
    return true

  # Retrieve all the widgets settings, build the new metadata parameter, and call pushMetadata
  w.updateSettings = (needContentReload=true) ->
    meta = {}
    angular.forEach(w.settings, (setting) ->
      extendDeep(meta,setting.toMetadata())
    )
    pushMetadata(meta, needContentReload) if !_.isEmpty(meta)
    return true

  # Push a new metadata parameter associated to the widget to Impac! and reload the widget content
  # should be considered as a private function: if it is called separately with only one setting,
  # the other settings will be reinitialized...
  pushMetadata = (newMetadata, needContentReload=true) ->
    return if _.isEmpty(newMetadata)
    data = { metadata: newMetadata }
    w.isLoading = true if needContentReload
    DhbAnalyticsSvc.widgets.update(w,data).then(
      (success) ->
        angular.extend(w,success.data)
        w.loadContent() if needContentReload
      , (errors) ->
        w.errors = Utilities.processRailsError(errors)
        w.isLoading = false
    )

  w.getColClass = ->
    "col-md-#{w.width}"
)

module.directive('impacWidget', ($templateCache) ->
  return {
    restrict: 'A',
    scope: {
      parentDashboard: '=',
      widget: '=',
      isAccessibility: '='
    },
    controller: 'ImpacWidgetCtrl',
    link: (scope, element) ->
      #=======================================
      # DYNAMIC WIDGET TEMPLATE LOADING
      # Widget data sent from Maestrano db have a category value in url format.
      # The structure of the url is `category/widget-template-name/data-extension`.
      # 'data-extension' means the widget re-uses a widget template, but signifies that
      # different data will be fed through.
      #=======================================
      scope.widgetContentTemplate = ->
        splittedPath = angular.copy(scope.widget.category).split("/")
        # remove any number of items beyond index 2 (eg: accounting_values is a template used by several different widgets)
        splittedPath.splice(2)
        # format into slug-case for filename matching
        scope.templateName = splittedPath.join("-").replace(/_/g, "-")
        # url for retreiving widget templates from angular $templateCache service.
        templatePath = "widgets/" + scope.templateName + ".tmpl.html"

        if scope.isAccessibility 
          if $templateCache.get("widgets/" + scope.templateName + ".accessible.tmpl.html")
            templatePath = "widgets/" + scope.templateName + ".accessible.tmpl.html"
          scope.templateName = scope.templateName + " accessible"

        return templatePath

      scope.isTemplateLoaded = ->
        return !!$templateCache.get(scope.widgetContentTemplate())

    ,templateUrl: "widget/widget.tmpl.html"
  }
)