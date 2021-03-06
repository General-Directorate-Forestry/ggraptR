# display plot or table
observeEvent(input$reactive, {
  updateButton(session, "submit", disabled = input$reactive)
  
  if (input$reactive) {
    output$plot <- renderPlot({  # display plot reactively
      buildPlot()
    }, height=700)
    output$displayTable <- DT::renderDataTable({  # display data table reactively
      DT::datatable(manAggDataset(), filter='top', 
                    # remove options to get back the global table search textInput
                    options = list(sDom  = '<"top">lrt<"bottom">ip'))
    })
  } else {
    output$plot <- renderPlot({  # display plot upon submit
      input$submit  # dependency
      isolate(buildPlot())
    }, height=700)
    output$displayTable <- DT::renderDataTable({  # display data table upon submit
      input$submit
      isolate(DT::datatable(manAggDataset(), filter='top',
                            options = list(sDom  = '<"top">lrt<"bottom">ip')))
    })
  }
})

# delay plot building until all controls will be ready
observe({
  nInp <- input$itersToDrawInp
  isolate({
    n <- reactVals$itersToDraw
    if (notNulls(nInp, n) && n != 0) reactVals$itersToDraw <- n - 1
  })
})

# trigger update for plopType options
observe({
  pTypes <- plotTypes()
  isolate({
    if (is.null(dataset())) return()
    allDefTypes <- unlist(getStructListNames(curDatasetPlotInputs()))
    needOneGroupOpts <- length(pTypes) == 1 && 
      length(plotTypesOpts()) == length(allDefTypes)
    
    if (is.null(pTypes) || needOneGroupOpts) {
      reactVals$plotTypeOptsTrigger <- Sys.time()  # Sys.time() for trigger
    }
  })
})

# reset inputs
observeEvent(input$reset_input, {
  updateCheckboxInput(session, "reactive", value = FALSE)
  Sys.sleep(0.5)
  # setdiff prevents very unstable bug of infinite recursive refresh of plotTypes
  for (id in setdiff(names(input), 'datasetName')) {
    reset(id)
  }
  Sys.sleep(0.5)
  updateCheckboxInput(session, "reactive", value = TRUE)
})

# disable/enable toggle between facet grid and facet wrap
observeEvent(buildPlot(), {
  if (!isFacetSelected()) {
    enable('facetRow')
    enable('facetCol')
    enable('facetWrap')
  } else if (facetGridSelected()) {
    enable('facetRow')
    enable('facetCol')
    disable('facetWrap')
  } else if (facetWrapSelected()) {
    disable('facetRow')
    disable('facetCol')
    enable('facetWrap')
  }
})

# collapse all extraPlotBlocks after init
observeEvent(buildPlot(), ({
  if (length(reactVals$log) == 1) {
    updateCollapse(session, "extraPlotBlocks", close = input$extraPlotBlocks)
  }
}))

# to prevent aggregated and limited dataframes collision
observeEvent(input$displayTable_search_columns, {
  if (tolower(plotAggMeth()) != 'none') reset('plotAggMeth')
})
