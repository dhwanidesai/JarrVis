# install.packages("shiny")
# install.packages("js")

#list of packages required
list.of.packages <- c("networkD3","dplyr","tidyr","reshape2","tidyverse","js","webshot")

#checking missing packages from list
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

#install missing ones
if(length(new.packages)) install.packages(new.packages, dependencies = TRUE)


library(shiny)

library(networkD3)

library(dplyr)
library(tidyr)
library(tidyverse)
library(reshape2)
library(js)
library(webshot)
webshot::install_phantomjs()
options(shiny.maxRequestSize=350*1024^2)

create_Nodes_DF <- function(stratified_table_lf)
{
  # Create noeds DF
  
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
  # my_color <- 'd3.scaleOrdinal() .domain(["a", "b"]) .range(["#69b3a2", "steelblue"])'
  # head(nodesDF_lf)
  return(nodesDF_lf)
}

create_Links_DF <- function(stratified_table_lf,NodesDF)
{
  links_DF_lf <- merge(stratified_table_lf, NodesDF, by.x = "Gene" , by.y = "name")
  links_DF_lf <- merge(links_DF_lf, NodesDF, by.x = "Genus" , by.y = "name")
  
  sampleNodes_lf <- unique(as.character(stratified_table_lf$Sample))
  sampleNodesDF_lf <- as.data.frame(sampleNodes_lf)
  colnames(sampleNodesDF_lf)[1] <- "samples"
  sampleNodesDF_lf <- cbind(node = 0:(nrow(sampleNodesDF_lf)-1), sampleNodesDF_lf)    # Applying cbind function
  
  links_DF_lf <- merge(links_DF_lf, sampleNodesDF_lf, by.x = "Sample", by.y = "samples")
  #links_DF <- merge(links_DF, sampleNodesDF, by.x = "s", by.y = "samples")  
  # links_DF_tax_samples_subset_lf <- select(links_DF_lf, node, node.y, Contribution)
  links_DF_tax_samples_subset_lf <- select(links_DF_lf, node, node.y, Contribution, Sample, Gene)
  links_DF_tax_samples_subset_lf <- setNames(links_DF_tax_samples_subset_lf, c("source","target","value","Sample","Function"))
  
  # links_DF_func_samples_subset_lf <- select(links_DF_lf, node, node.x, Contribution)
  # links_DF_func_samples_subset_lf <- setNames(links_DF_func_samples_subset_lf, c("source","target","value"))
  
  links_DF_TaxFunc_subset_lf <- select (links_DF_lf, node.y, node.x, Contribution, Sample, Gene)
  links_DF_TaxFunc_subset_lf <- setNames(links_DF_TaxFunc_subset_lf, c("source","target","value","Sample","Function"))
  
  # final_links_DF_lf <- bind_rows(links_DF_tax_samples_subset_lf, links_DF_func_samples_subset_lf, links_DF_TaxFunc_subset_lf)
  final_links_DF_lf <- bind_rows(links_DF_tax_samples_subset_lf, links_DF_TaxFunc_subset_lf)
  #final_links_DF_filtered_lf <- subset(final_links_DF_lf, value > 5) # Filter out links with contributions == 0
  
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
      
      checkboxInput("header", "Header", TRUE),
      
      selectInput("filter", "Filtercollapse the dataframe", choices = c("Yes","No"), selected = "Yes"),
      selectInput("level", "Taxonomy level to collapse",choices = c("Phylum","Class","Order","Family","Genera","Species",""), selected = "Genera"),
      selectInput("metaCat", "Metadata Categories", choices = c()),
      numericInput("contribThresh", "RPKM threshold filter",10),
      radioButtons("saveType", "Save Plot as",choices = c("png","pdf","jpeg"), selected = "png")
    ),
    mainPanel(
    # textOutput("filtered"),
    # textOutput("taxlevel"),
    # textOutput("contrib_threshold"),
    # uiOutput("metCat"),  
    sankeyNetworkOutput("SNNET", width = "100%", height = "100%"),
    downloadButton("downld", label = "Download the Plot")
    )
  )
  
)


server <- function(session, input, output) {
  
  ## Read the stratified file in longform TSV
  stratified_table_longform_data <- reactive({
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, it will be a data frame with 'name',
    # 'size', 'type', and 'datapath' columns. The 'datapath'
    # column will contain the local filenames where the data can
    # be found.
    # req(input$stratTableLFfile, input$header, file.exists(input$stratTableLFfile$datapath))
    # read.csv(input$stratTableLFfile$datapath, header = input$header)
    file1 <- input$stratTableLFfile
    # if(is.null(file1)){return()}
    req(input$stratTableLFfile, input$header, file.exists(input$stratTableLFfile$datapath))
    read.table(file = file1$datapath, sep = '\t', header = input$header)

  })

  metadata_table_data <- reactive({
    file2 <- input$MetadataTablefile
    req(input$MetadataTablefile, input$header, file.exists(input$MetadataTablefile$datapath))
    read.table(file = file2$datapath, sep = '\t', header = input$header)
    })
  
  metadata <- reactive({
    metadataDF <- metadata_table_data()
    message ("metadata sample categories:",colnames(metadataDF))
    updateSelectInput(session,"metaCat",choices = c(as.character(colnames(metadataDF))))    
    return(metadataDF)    
  })
  
  metadata_category <- reactive({input$metaCat})
  # output$metCat <- renderUI({
  #   metadataDf <- metadata_table_data()
  #   
  #   # as.character: to get names of levels and not a numbers as choices in case of factors
  #   items <- as.character(colnames(metadataDf))
  #   
  #   selectInput("metaCat-dropdown", "Metadata Categories:", items)
  # })
  
  filtered <- reactive({input$filter})
  taxlevel <- reactive({input$level})
  contrib_threshold <- reactive({input$contribThresh})
  # print(filtered)
  
  #output$filtered <- renderText({paste0(input$filter)})
  # output$taxlevel <- renderText({paste0(input$level)})
  # output$contrib_threshold <- renderText({paste0(input$contribThresh)})
  
  
  
  

  nodes_links_dfs_list <- reactive({
    
    stratified_table_longform <- stratified_table_longform_data()
    # if (is.null(stratfified_table_longform)) return(NULL)
    message ("Input table dims:",dim(stratified_table_longform))
    
    if (filtered() != TRUE && taxlevel() == ''){
    message ("The value for Taxa level collapsing:",filtered())
    stratified_table_longform_filtered <- subset(stratified_table_longform, Contribution > 0) # Filter out links with contributions == 0
    nodesDF_longform <- create_Nodes_DF(stratified_table_longform_filtered)
    linksDF_longform <- create_Links_DF(stratified_table_longform, nodesDF_longform)
   }else
     {
    message ("The value for Taxa level collapsing:",taxlevel())
    stratified_table_longform_tax_collapsed <- collapseTableByTaxonomy(stratified_table_longform,taxlevel())
    
    message ("The Sample Category for  collapsing:",metadata_category())
    stratified_table_longform_sample_collapsed <- collapseTableBySampleMetadata(stratified_table_longform_tax_collapsed,metadata(),metadata_category())
    message ("Collapsed table dims:",dim(stratified_table_longform_sample_collapsed))
    stratified_table_longform_collapsed_filtered <- subset(stratified_table_longform_sample_collapsed, Contribution > as.numeric(contrib_threshold())) # Filter out links with contributions == 0
    nodesDF_longform <- create_Nodes_DF(stratified_table_longform_collapsed_filtered)
    linksDF_longform <- create_Links_DF(stratified_table_longform_collapsed_filtered, nodesDF_longform)
     }
    message ("FINAL node table dims:",dim(nodesDF_longform))
    nodesLinksDFlist <- list(nodes=nodesDF_longform,links=linksDF_longform)
    return(nodesLinksDFlist)
})
  
  snNET <- reactive ({
    # DFsList <- nodes_links_dfs_list()
    nodesDF_longform <- nodes_links_dfs_list()$nodes
    linksDF_longform <- nodes_links_dfs_list()$links
    message ("NODES DF dims:",dim(nodesDF_longform))
    my_color <- JS('d3.scaleOrdinal().domain(["red", "blue", "green"]).range(["#FF0000","#0000FF","#00FF00"])')
    
    snet <- sankeyNetwork(Links = linksDF_longform, Nodes = nodesDF_longform, Source = "source",
                  Target = "target", Value = "value", NodeID = "name", NodeGroup = "Group",
                  colourScale = my_color, 
                  units = "RPKM", fontSize = 14, nodeWidth = 30, sinksRight = T)
    snet$x$links$Sample <- linksDF_longform$Sample
    snet$x$links$Function <- linksDF_longform$Function
    return(snet)
  })
  
  
  output$SNNET <- renderSankeyNetwork({
    snNET()
    # snNET$x$links$traveler <- links$traveler
    
    htmlwidgets::onRender(
      snNET(),
      '
      function(el, x) {
      var nodes = d3.selectAll(".node");
      var links = d3.selectAll(".link");
      nodes.select("rect").style("cursor", "pointer");
      nodes.on("mousedown.drag", null); // remove the drag because it conflicts
      //nodes.on("mouseout", null);
      nodes.on("click", clicked);
      function clicked(d, i) {
        links
          .style("stroke-opacity", function(d1) {
              if(d1.Function === d.name){
              return 0.5
              }
              else if(d1.Sample === d.name){
              return 0.5
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
    
    saveNetwork(snNET(), "./sampCollapsed_sn.html")
    webshot("./sampCollapsed_sn.html",file)
    
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
