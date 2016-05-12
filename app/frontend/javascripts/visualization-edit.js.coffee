# Imports
VisualizationModel           = require './models/visualization.js'
NodesCollection              = require './collections/nodes-collection.js'
RelationsCollection          = require './collections/relations-collection.js'
VisualizationGraph           = require './views/visualization-graph.js'
VisualizationTableNodes      = require './views/visualization-table-nodes.js'
VisualizationTableRelations  = require './views/visualization-table-relations.js'

class VisualizationEdit

  mainHeaderHeight:             84
  visualizationHeaderHeight:    91
  tableHeaderHeight:            42

  id:                           null
  nodes:                        null
  visualizationGraph:           null
  visualizationTable:           null
  visualizationTableNodes:      null
  visualizationTableRelations:  null
  $tableSelector:               null

  constructor: (_id) ->
    console.log('setup visualization', _id);
    @id = _id
    # Setup Visualization Model
    @visualization  = new VisualizationModel()
    # Setup Collections
    @nodes          = new NodesCollection()
    @relations      = new RelationsCollection()
    # Setup Views
    @visualizationTableNodes      = new VisualizationTableNodes {model: @visualization, collection: @nodes}
    @visualizationTableRelations  = new VisualizationTableRelations {model: @visualization, collection: @relations}
    @visualizationGraph           = new VisualizationGraph {model: @visualization, collection: {nodes: @nodes, relations: @relations} }
    # Attach nodes to VisualizationTableRelations
    @visualizationTableRelations.setNodes @nodes
    # Setup Table Tab Selector
    $('#visualization-table-selector > li > a').click @updateTable
    # Setup visualization table
    @visualizationTable = $('.visualization-table')
    # Setup scrollbar link
    $('.visualization-table-scrollbar a').click (e) ->
      e.preventDefault()
      $('html, body').animate { scrollTop: $(document).height() }, 1000
    # Setup scroll handler
    $(window).scroll @onScroll

  setupAffix: ->
    $('.visualization-graph').affix
      offset:
        top: @mainHeaderHeight + @visualizationHeaderHeight

  updateTable: (e) =>
    e.preventDefault()
    if $(e.target).parent().hasClass('active')
      return
    # Show tab
    $(e.target).tab('show')
    # Update table
    $('.visualization-table .tab-pane.active').removeClass('active');
    $('.visualization-table '+$(e.target).attr('href')).addClass('active')
    if $(e.target).attr('href') == '#nodes'
      @visualizationTableRelations.hide()
      @visualizationTableNodes.show()
    else
      @visualizationTableNodes.hide()
      @visualizationTableRelations.show()

  resize: =>
    console.log 'resize!'
    windowHeight = $(window).height()
    graphHeight = windowHeight - @mainHeaderHeight - @visualizationHeaderHeight - @tableHeaderHeight
    tableHeight = (windowHeight*0.5) + @tableHeaderHeight
    @visualizationGraph.$el.height graphHeight
    @visualizationGraph.resize()
    @visualizationTable.css 'top', graphHeight + @visualizationHeaderHeight
    @visualizationTable.height tableHeight
    @visualizationTableNodes.setSize tableHeight, @visualizationTable.offset().top
    @visualizationTableRelations.setSize tableHeight, @visualizationTable.offset().top
    #$('.footer').css 'top', graphHeight + @visualizationHeaderHeight

  onScroll: =>
    @visualizationGraph.setOffsetY $(window).scrollTop() - @mainHeaderHeight - @visualizationHeaderHeight

  render: ->
    # setup affix bootstrap
    @setupAffix()
    # force resize
    @resize()
    # fetch model & collections
    syncCounter = _.after 3, @onSync
    @visualization.fetch  {url: '/api/visualizations/'+@id,               success: syncCounter}
    @nodes.fetch          {url: '/api/visualizations/'+@id+'/nodes/',     success: syncCounter}
    @relations.fetch      {url: '/api/visualizations/'+@id+'/relations/', success: syncCounter}

  onSync: =>
    # Render Tables & Graph when all collections ready
    @visualizationTableNodes.render()
    @visualizationTableRelations.render()
    @visualizationGraph.render()

module.exports = VisualizationEdit;