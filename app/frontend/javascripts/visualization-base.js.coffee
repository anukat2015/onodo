# Imports
Visualization                = require './models/visualization.js'
Node                         = require './models/node.js'
NodesCollection              = require './collections/nodes-collection.js'
RelationsCollection          = require './collections/relations-collection.js'
VisualizationCanvas          = require './views/visualization-canvas.js'
VisualizationConfiguration   = require './views/visualization-configuration.js'
VisualizationNavigation      = require './views/visualization-navigation.js'
VisualizationInfo            = require './views/visualization-info.js'

class VisualizationBase

  id:                         null
  edit:                       false
  nodes:                      null
  visualizationCanvas:        null
  visualizationConfiguration: null
  visualizationNavigation:    null
  visualizationInfo:          null

  constructor: (_id) ->
    console.log 'setup visualization base'
    @id = _id
    # Setup Visualization Model
    @visualization      = new Visualization()
    # Setup Collections
    @nodes              = new NodesCollection()
    @relations          = new RelationsCollection()
    # Setup Views
    @visualizationCanvas         = new VisualizationCanvas()
    @visualizationConfiguration  = new VisualizationConfiguration()
    @visualizationNavigation     = new VisualizationNavigation()
    @visualizationInfo           = new VisualizationInfo()
    # Setup Configure Panel Show/Hide
    $('.visualization-graph-menu-actions .btn-configure').click @onPanelConfigureShow
    $('.visualization-graph-panel-configuration .close').click  @onPanelConfigureHide
    # Setup Share Panel Show/Hide
    $('.visualization-graph-menu-actions .btn-share').click     @onPanelShareShow
    $('#visualization-share .close').click                      @onPanelShareHide

  render: ->
    # force resize
    @resize()
    # fetch model & collections
    syncCounter = _.after 3, @onSync
    @visualization.fetch  {url: '/api/visualizations/'+@id,               success: syncCounter}
    @nodes.fetch          {url: '/api/visualizations/'+@id+'/nodes/',     success: syncCounter}
    @relations.fetch      {url: '/api/visualizations/'+@id+'/relations/', success: syncCounter}

  resize: =>
    if @visualizationCanvas and @visualizationCanvas.svg
      @visualizationCanvas.resize()

  onSync: =>
    # Setup visualizationConfiguration model
    @visualizationConfiguration.model = @visualization
    @visualizationConfiguration.render()
    # Setup VisualizationCanvas
    @visualizationCanvas.setup @getVisualizationCanvasData(@nodes.models, @relations.models), @visualizationConfiguration.parameters
    @visualizationCanvas.render()
    # Subscribe VisualizationCanvas Events
    Backbone.on 'visualization.node.showInfo',         @onNodeShowInfo, @
    Backbone.on 'visualization.node.hideInfo',         @onNodeHideInfo, @
    # Subscribe Navigation Events
    Backbone.on 'visualization.navigation.zoomin',     @onZoomIn, @
    Backbone.on 'visualization.navigation.zoomout',    @onZoomOut, @
    Backbone.on 'visualization.navigation.fullscreen', @onFullscreen, @
    # Trigger synced event for Stories
    Backbone.trigger 'visualization.synced'

  # Format data from nodes & relations collections for VisualizationCanvas
  getVisualizationCanvasData: ( nodes, relations ) ->
    data =
      nodes:      nodes.map     (d) -> return d.attributes
      relations:  relations.map (d) -> return d.attributes
    # Fix relations source & target index (based on 1 instead of 0)
    data.relations.forEach (d) ->
      d.source = d.source_id-1
      d.target = d.target_id-1
    return data

  # Canvas Events
  onNodeShowInfo: (e) ->
    #console.log 'show info', e.node, @visualization
    @visualizationCanvas.focusNode e.node
    @visualizationInfo.show new Node(e.node), @visualization.get('custom_fields')

  onNodeHideInfo: (e) ->
    @visualizationCanvas.unfocusNode()
    @visualizationInfo.hide()

  # Panel Events
  onPanelConfigureShow: =>
    $('html, body').animate { scrollTop: 0 }, 600
    @visualizationConfiguration.$el.addClass 'active'
    @visualizationCanvas.setOffsetX 200 # half the width of Panel Configuration

  onPanelConfigureHide: =>
    @visualizationConfiguration.$el.removeClass 'active'
    @visualizationCanvas.setOffsetX 0

  onPanelShareShow: ->
    $('#visualization-share').addClass 'active'

  onPanelShareHide: ->
    $('#visualization-share').removeClass 'active'

  # Navigation Events
  onZoomIn: (e) ->
    @visualizationCanvas.zoomIn()
    
  onZoomOut: (e) ->
    @visualizationCanvas.zoomOut()

  onFullscreen: (e) ->
    $('body').toggleClass 'fullscreen'
    @resize()

module.exports = VisualizationBase