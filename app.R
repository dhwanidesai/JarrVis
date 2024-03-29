# install.packages("shiny")
# install.packages("js")

#list of packages required
list.of.packages <- c("networkD3","shinyWidgets","dplyr","tidyr","reshape2","tidyverse","js","webshot","stringr")

#checking missing packages from list
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

#install missing ones
if(length(new.packages)) install.packages(new.packages, dependencies = TRUE)


library(shiny)
library(shinyWidgets)
library(networkD3)

library(dplyr)
library(tidyr)
library(tidyverse)
library(reshape2)
library(js)
library(webshot)
library(stringr)
webshot::install_phantomjs()
options(shiny.maxRequestSize=1000*1024^2)

create_Nodes_DF <- function(stratified_table_lf)
{
  # Create nodes DF
  
  # Separate the Sample,taxa and function nodes and get their counts
  
  taxNodes_lf <- unique(as.character(stratified_table_lf$Genus))
  taxNodes_length <- length(taxNodes_lf)
  funcNodes_lf <- unique(as.character(stratified_table_lf$Gene))
  funcNodes_length <- length(funcNodes_lf)
  #sampleNodes <- as.character(colnames(stratified_table_lf)[3:ncol(stratified_table)])
  sampleNodes_lf <- unique(as.character(stratified_table_lf$Sample))
  sampleNodes_length <- length(sampleNodes_lf)
  
  nodesDF_lf <- data.frame(c(sampleNodes_lf,taxNodes_lf,funcNodes_lf))
  colnames(nodesDF_lf)[1] <- "name"
  #nodesDF <- tibble::rowid_to_column(nodesDF, "node")
  nodesDF_lf <- cbind(node = 0:(nrow(nodesDF_lf)-1), nodesDF_lf)    # Applying cbind function
  # Add a factor for specifying groups of nodes i.e 
  # a separate group for Samples, taxa and function nodes  
  color_seq <- c("red","blue","green")
  length_seq <- c(sampleNodes_length,taxNodes_length,funcNodes_length)
  nodesDF_lf$Group <- as.character(rep(color_seq[1:3], length_seq))
  # Add 3 fields in nodes DF to distinguish Sample, Taxa and Functions nodes
  # This will be useful in onRender to control the placement
  nodesDF_lf <- transform(
    nodesDF_lf, SampleTarget = ifelse(nodesDF_lf$Group=="red", TRUE, FALSE))
  nodesDF_lf <- transform(
    nodesDF_lf, TaxaTarget = ifelse(nodesDF_lf$Group=="blue", TRUE, FALSE))
  nodesDF_lf <- transform(
    nodesDF_lf, FuncTarget = ifelse(nodesDF_lf$Group=="green", TRUE, FALSE))

  return(nodesDF_lf)
}

create_Links_DF <- function(stratified_table_lf,NodesDF)
{
  #Create a links dataframe by merging Strat table with nodes DF
  # using the column Gene from Strat table and Name from nodes dF
  
  # Then merge this links DF again with the nodes DF using column
  # Genus (for taxa) and Name from nodes DF
  
  links_DF_lf <- merge(stratified_table_lf, NodesDF, by.x = "Gene" , by.y = "name")
  links_DF_lf <- merge(links_DF_lf, NodesDF, by.x = "Genus" , by.y = "name")
  
  # Now to add node numbers (starting form 0) instead of names
  # There appears to be a redundancy here...
  # sampleNodes_lf would have the same info as nodesDF above 
  
  sampleNodes_lf <- unique(as.character(stratified_table_lf$Sample))
  sampleNodesDF_lf <- as.data.frame(sampleNodes_lf)
  colnames(sampleNodesDF_lf)[1] <- "samples"
  sampleNodesDF_lf <- cbind(node = 0:(nrow(sampleNodesDF_lf)-1), sampleNodesDF_lf)    # Applying cbind function
  
  links_DF_lf <- merge(links_DF_lf, sampleNodesDF_lf, by.x = "Sample", by.y = "samples")
  links_DF_tax_samples_subset_lf <- select(links_DF_lf, node, node.y, Contribution, Sample, Gene)
  links_DF_tax_samples_subset_lf <- setNames(links_DF_tax_samples_subset_lf, c("source","target","value","Sample","Function"))
  
  links_DF_TaxFunc_subset_lf <- select (links_DF_lf, node.y, node.x, Contribution, Sample, Gene)
  links_DF_TaxFunc_subset_lf <- setNames(links_DF_TaxFunc_subset_lf, c("source","target","value","Sample","Function"))
  
  
  final_links_DF_lf <- bind_rows(links_DF_tax_samples_subset_lf, links_DF_TaxFunc_subset_lf)
  
  return(final_links_DF_lf)
}

collapseTableByTaxonomy <- function(strat_table_lf,level)
{
  strat_table_lf_split <- separate(data = strat_table_lf, 
                                   col = Genus, 
                                   into = c("Phylum","Class","Order","Family","Genera","Species"), 
                                   sep = ";")  
  
  strat_table_lf_split_collapsed <- strat_table_lf_split %>% 
    group_by(Sample,strat_table_lf_split[[level]],Gene) %>% 
    summarise(mean = mean(Contribution), n = n())
  
  strat_table_lf_split_collapsed <- setNames(strat_table_lf_split_collapsed, 
                                             c("Sample","Genus","Gene","Contribution","n"))
  
  #strat_table_lf_split_collapsed <- subset(strat_table_lf_split_collapsed, Genus != "NA", select = c("Sample","Genus","Gene","Contribution","n"))
  #str_detect(type, 'Toyota|Mazda'))
  strat_table_lf_split_collapsed <- strat_table_lf_split_collapsed %>%
    filter(str_detect(Genus,"NA", negate = T))
  message("In collapse by tax, after filtering NA", colnames(strat_table_lf_split_collapsed),dim(strat_table_lf_split_collapsed))
  return(strat_table_lf_split_collapsed)  
}

collapseTableBySampleMetadata <- function(strat_tbl_lf_taxCollapsed_df,metadata_df,samp_cat)
{
  message("in collapse by sample", dim(strat_tbl_lf_taxCollapsed_df))
  strat_tbl_lf_taxCollapsed_df <- merge(strat_tbl_lf_taxCollapsed_df,metadata_df, by.x = "Sample", by.y = "sample_id")
  
  strat_tbl_lf_taxCollapsed_sampCollapsed <- strat_tbl_lf_taxCollapsed_df %>% 
    group_by(strat_tbl_lf_taxCollapsed_df[[samp_cat]],Genus,Gene) %>% 
    summarise(mean = mean(Contribution), n = n())
  message("in collapse by sample...final sample collapsed table", dim(strat_tbl_lf_taxCollapsed_sampCollapsed))
  
  strat_tbl_lf_taxCollapsed_sampCollapsed <- setNames(strat_tbl_lf_taxCollapsed_sampCollapsed, 
                                                      c("Sample","Genus","Gene","Contribution","n"))
  return(strat_tbl_lf_taxCollapsed_sampCollapsed)
}


ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      fileInput("stratTableLFfile", "Upload stratified output File (TSV)",
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv",".txt")
      ),
      # tags$hr(),
      fileInput("MetadataTablefile", "Upload Sample Metadata File (TSV)",
                accept = c(
                  "text/csv",
                  "text/comma-separated-values,text/plain",
                  ".csv",".txt")
      ),
      actionButton("selMetaCat","Select Metadata Categories"),
      selectInput("metaCat", "Metadata Categories", choices = c()),
      
      #checkboxInput("header", "Header", TRUE),
      
      #selectInput("filter", "Filtercollapse the dataframe", choices = c("Yes","No"), selected = "Yes"),
      selectInput("level", "Taxonomy level to collapse",choices = c("Phylum","Class","Order","Family","Genera","Species",""), selected = "Genera"),
      
      #numericInput("contribThresh", "RPKM threshold filter",10),
      actionButton("selTaxCat","Select Taxa Categories"),
      pickerInput("TaxCat","Filter by Taxa", choices = c(),
                  options = pickerOptions(
                    actionsBox = TRUE,
                    liveSearch = TRUE,
                    liveSearchNormalize = TRUE
                    ),
                  multiple = T),
      
      actionButton("selFuncCat","Select Function Categories"),
      pickerInput("FuncCat","Filter by Functions", choices = c(),
                  options = pickerOptions(
                    actionsBox = TRUE,
                    liveSearch = TRUE,
                    liveSearchNormalize = TRUE
                  ),
                  multiple = T),
      
      actionButton("updateThresh", "Update the Gene Contribution Threshold from data", 
                   style="color: #000000; white-space:normal;"),
      sliderInput("contribThresh", label = "", min = 5, max = 10, step=0.1, value = c(5,10)),
      
      #uiOutput("threshold_slider"),
      radioButtons("saveType", "Save Plot as",choices = c("html","png","pdf","jpeg"), selected = "html")
    ),
    mainPanel(
    # textOutput("filtered"),
    # textOutput("taxlevel"),
    # textOutput("contrib_threshold"),
    # uiOutput("metCat"),  
    sankeyNetworkOutput("SNNET", width = "2000px", height = "2000px"),
    #sankeyNetworkOutput("SNNET"),  
    actionButton("run","Display Plot"),
    downloadButton("downld", label = "Download Plot")
    )
  )
  
)


server <- function(session, input, output) {
  
  ## Read the stratified file in longform TSV
  stratified_table_longform_data <- eventReactive(input$selTaxCat,{
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, it will be a data frame with 'name',
    # 'size', 'type', and 'datapath' columns. The 'datapath'
    # column will contain the local filenames where the data can
    # be found.
    # req(input$stratTableLFfile, input$header, file.exists(input$stratTableLFfile$datapath))
    # read.csv(input$stratTableLFfile$datapath, header = input$header)
    file1 <- input$stratTableLFfile
    # if(is.null(file1)){return()}
    req(input$stratTableLFfile, file.exists(input$stratTableLFfile$datapath))
    read.table(file = file1$datapath, sep = '\t', header = TRUE, fill = TRUE)

  })

  metadata_table_data <- eventReactive(input$selMetaCat,{
    file2 <- input$MetadataTablefile
    req(input$MetadataTablefile, file.exists(input$MetadataTablefile$datapath))
    read.table(file = file2$datapath, sep = '\t', header = TRUE)
    })
  
  metadata_cat_update <- observeEvent(input$selMetaCat,{
    metadataDF <- metadata_table_data()
    message ("metadata sample categories:",colnames(metadataDF))
    updateSelectInput(session,"metaCat",choices = c(as.character(colnames(metadataDF)[2:length(colnames(metadataDF))])))    
    #return(metadataDF)    
  })
  
  #metadataDF <- reactive()
  metadata_category <- reactive({input$metaCat})
  
  Taxa_cat_update <- observeEvent(input$selTaxCat,{
    dataDF <- stratified_table_longform_data()
    message ("Taxa categories:",unique(dataDF$Genus))
    updatePickerInput(session,"TaxCat",choices = c(as.character(sort(unique(dataDF$Genus)))))    
    #return(metadataDF)    
  })
  
  #metadataDF <- reactive()
  Tax_category <- reactive({input$TaxCat})
  
  Func_cat_update <- observeEvent(input$selFuncCat,{
    dataDF <- stratified_table_longform_data()
    message ("Function categories:",unique(dataDF$Gene))
    updatePickerInput(session,"FuncCat",choices = c(as.character(sort(unique(dataDF$Gene)))))    
    #return(metadataDF)    
  })
  
  #metadataDF <- reactive()
  Func_category <- reactive({input$FuncCat})
  
  Threshold_Slider_update <- observeEvent(input$updateThresh, {
    inputTableDF <- stratified_table_longform_data()
    inputTableDF <- subset(inputTableDF, Contribution > 0, select = c(Sample,Genus,Gene,Contribution))
    message ("in update Thresh input table dims", dim(inputTableDF))
    updateSliderInput(
    session, "contribThresh",
                    min = min(inputTableDF$Contribution), 
                    max = max(inputTableDF$Contribution),
                    value = c(median(inputTableDF$Contribution),max(inputTableDF$Contribution))
                    )
    })         
  contrib_threshold <- reactive({input$contribThresh})
 # contrib_threshold_min <- contrib_threshold()[0]
#  contrib_threshold_max <- contrib_threshold()[1]
    # output$metCat <- renderUI({
  #   metadataDf <- metadata_table_data()
  #   
  #   # as.character: to get names of levels and not a numbers as choices in case of factors
  #   items <- as.character(colnames(metadataDf))
  #   
  #   selectInput("metaCat-dropdown", "Metadata Categories:", items)
  # })
  
  #filtered <- eventReactive(input$run,{input$filter})
  filtered <- TRUE
  taxlevel <- eventReactive(input$run,{input$level})
  #contrib_threshold <- eventReactive(input$run,{input$contribThresh})
  
  # print(filtered)
  
  #output$filtered <- renderText({paste0(input$filter)})
  # output$taxlevel <- renderText({paste0(input$level)})
  # output$contrib_threshold <- renderText({paste0(input$contribThresh)})
  

  nodes_links_dfs_list <- eventReactive(input$run,{
    
    stratified_table_longform <- stratified_table_longform_data()
    stratified_table_longform <- subset(stratified_table_longform, Contribution > 0, select = c(Sample,Genus,Gene,Contribution))
    
    # if (is.null(stratfified_table_longform)) return(NULL)
    message ("Input table dims:",dim(stratified_table_longform))
    
    if (filtered != TRUE && taxlevel() == ''){
    message ("The value for Taxa level collapsing:",filtered)
    #stratified_table_longform_filtered <- subset(stratified_table_longform, Contribution > 0) # Filter out links with contributions == 0
    nodesDF_longform <- create_Nodes_DF(stratified_table_longform)
    linksDF_longform <- create_Links_DF(stratified_table_longform, nodesDF_longform)
   }else
     {
    message ("The value for Taxa level collapsing:",taxlevel())
    message ("Init table dims:",dim(stratified_table_longform))   
    message ("Selected Taxa are:",Tax_category())
    #Tax_search_regex <- paste0(Tax_category(),collapse = "|")
    #message ("Selected Taxa search string:",Tax_search_regex)
    
    message ("Selected Funtions are:",Func_category())
    #Func_search_regex <- paste0(Func_category(),collapse = "|")
    #message ("Selected Function search string:",Func_search_regex)
    
    stratified_table_longform_TaxFiltered <- stratified_table_longform %>%
            filter(Genus %in% Tax_category())
    message ("Table after Tax keyword filter:",dim(stratified_table_longform_TaxFiltered))
    
    stratified_table_longform_TaxFiltered_FuncFiltered <- stratified_table_longform_TaxFiltered %>%
         filter(Gene %in% Func_category())
    message ("Table after Func keyword filter:",dim(stratified_table_longform_TaxFiltered_FuncFiltered))
    
    stratified_table_longform_tax_collapsed <- collapseTableByTaxonomy(stratified_table_longform_TaxFiltered_FuncFiltered,taxlevel())
    
    message ("The Sample Category for  collapsing:",metadata_category())
    stratified_table_longform_sample_collapsed <- collapseTableBySampleMetadata(stratified_table_longform_tax_collapsed,metadata_table_data(),metadata_category())
    message ("Collapsed table dims:",dim(stratified_table_longform_sample_collapsed))
    
    message ("Threshold values:",contrib_threshold())
    contrib_range <- contrib_threshold()
    contrib_min <- contrib_range[1]
    contrib_max <- contrib_range[2]
    message ("Threshold range min:",contrib_min)
    message ("Threshold range max:",contrib_max)
    stratified_table_longform_collapsed_filtered <- subset(stratified_table_longform_sample_collapsed, 
                                                           subset = (Contribution >= as.numeric(contrib_min) 
                                                                     & Contribution <= as.numeric(contrib_max))) 
    
    message ("Final filtered input:",dim(stratified_table_longform_collapsed_filtered))
    #stratified_table_longform_collapsed_filtered <- subset(stratified_table_longform_sample_collapsed, 
     #                                                      Contribution >= as.numeric(contrib_threshold())) 
    
    nodesDF_longform <- create_Nodes_DF(stratified_table_longform_collapsed_filtered)
    linksDF_longform <- create_Links_DF(stratified_table_longform_collapsed_filtered, nodesDF_longform)
     }
    message ("FINAL node table dims:",colnames(nodesDF_longform),dim(nodesDF_longform))
    nodesLinksDFlist <- list(nodes=nodesDF_longform,links=linksDF_longform)
    return(nodesLinksDFlist)
})
  
  snNET <- reactive ({
    # DFsList <- nodes_links_dfs_list()
    nodesDF_longform <- nodes_links_dfs_list()$nodes
    linksDF_longform <- nodes_links_dfs_list()$links
    message ("LINKS DF dims:",colnames(linksDF_longform))
    my_color <- JS('d3.scaleOrdinal().domain(["red", "blue", "green"]).range(["#FF0000","#0000FF","#00FF00"])')
    
    snet <- sankeyNetwork(Links = linksDF_longform, Nodes = nodesDF_longform, Source = "source",
                  Target = "target", Value = "value", NodeID = "name", NodeGroup = "Group",
                  colourScale = my_color, 
                  units = "RPKM", fontSize = 10, nodeWidth = 20, sinksRight = F)
    snet$x$links$Sample <- linksDF_longform$Sample
    snet$x$links$Function <- linksDF_longform$Function
    snet$x$nodes$Sample <- nodesDF_longform$SampleTarget
    snet$x$nodes$Function <- nodesDF_longform$FuncTarget
    snet$x$nodes$Taxa <- nodesDF_longform$TaxaTarget
    return(snet)
  })
  
  
  output$SNNET <- renderSankeyNetwork({
    snNET() 
    htmlwidgets::onRender(
      snNET(),
      '
      function(el, x) {
      
      d3.selectAll(".node text")
      .attr("font-weight", "bold");
      
      d3.select(el)
      .selectAll(".node text")
      .filter(d => d.Sample)
      .attr("x", -10)
      .attr("text-anchor", "begin");
      d3.select(el)
      .selectAll(".node text")
      .filter(d => d.Function)
      .attr("x", 20)
      .attr("text-anchor", "begin");  
      d3.select(el)
      .selectAll(".node text")
      .filter(d => d.Taxa)
      .attr("x", -10)
      .attr("text-anchor", "end");
      
      var nodes = d3.selectAll(".node");
      var links = d3.selectAll(".link");
      nodes.select("rect").style("cursor", "pointer");
      //nodes.on("mousedown.drag", null); // remove the drag because it conflicts
      //nodes.on("mouseout", null);
      el.addEventListener(
      "contextmenu",
      (ev) => {
      ev.preventDefault();
      nodes.on("contextmenu", clicked);
      }
      );
      
      //nodes.on("mousedown", clicked);
      function clicked(d, i) {
        links
          .style("stroke-opacity", function(d1) {
              if(d1.Function === d.name){
              return 0.8
              }
              else if(d1.Sample === d.name){
              return 0.8
              }
              else{
              return 0.2
              }
          });
      }

  }
  '
  )
  })
  
  snnet_final <- reactive ({
    htmlwidgets::onRender(
    snNET(),
    '
      function(el, x) {

      d3.selectAll(".node text")
      .attr("font-weight", "bold");

      d3.select(el)
      .selectAll(".node text")
      .filter(d => d.Sample)
      .attr("x", -10)
      .attr("text-anchor", "begin");
      d3.select(el)
      .selectAll(".node text")
      .filter(d => d.Function)
      .attr("x", 20)
      .attr("text-anchor", "begin");
      d3.select(el)
      .selectAll(".node text")
      .filter(d => d.Taxa)
      .attr("x", -10)
      .attr("text-anchor", "end");

      var nodes = d3.selectAll(".node");
      var links = d3.selectAll(".link");
      nodes.select("rect").style("cursor", "pointer");
      //nodes.on("mousedown.drag", null); // remove the drag because it conflicts
      //nodes.on("mouseout", null);
      el.addEventListener(
      "contextmenu",
      (ev) => {
      ev.preventDefault();
      nodes.on("contextmenu", clicked);
      }
      );

      //nodes.on("mousedown", clicked);
      function clicked(d, i) {
        links
          .style("stroke-opacity", function(d1) {
              if(d1.Function === d.name){
              return 0.8
              }
              else if(d1.Sample === d.name){
              return 0.8
              }
              else{
              return 0.2
              }
          });
      }

  }
  '
  )
  })
  
  # snnet_final <- eventReactive (output$downld,{
  #   htmlwidgets::saveWidget(snNET(), "./sampCollapsed_sn.html")
  #   })
  # 
  
  # output$filtered <- reactive({(paste0(input$filter))})
  # output$taxlevel <- reactive({(paste0(input$level))})
  # output$contrib_threshold <- reactive({(paste0(input$contribThresh))})
  
  output$downld <- downloadHandler(
    # Specify the file name for storing the output plot
    filename = function(){
    # SankeyPlot.png
    paste("SankeyPlot", input$saveType, sep=".")
  },
  content = function(file){
    # Open the device
    # Write the plot
    # Close device
    if(input$saveType == "html")
    {
      message("In save, html file:", file)
      htmlwidgets::saveWidget(widget = snnet_final(), file = file)
    }else{
        htmlwidgets::saveWidget(snnet_final(), "./sampCollapsed_sn.html")
        webshot("./sampCollapsed_sn.html",file)
    }
    # dev.off
  }
  )
  
  session$onSessionEnded(function() {
    if (!is.null("./sampCollapsed_sn.html")) {
      file.remove("./sampCollapsed_sn.html")
    }
  })
  
}

shinyApp(ui, server)
