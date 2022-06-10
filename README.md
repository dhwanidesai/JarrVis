# JarrVis
A shiny app for visualizing stratified rpkm output from metagenomic pipelines - JARRVIS (Just Another stRatified Rpkm VISualizer)

#  <p align="center">  
#    <img src="your_relative_path_here" width="350" title="hover text">  
#   <img src="your_relative_path_here_number_2_large_name" width="350" alt="accessibility text">  
#  </p>  

This repository provides the source code and the test data files for running the JarrVis app locally.

To run this app you would require a local install of Rstudio (R version 3.6) with the shiny package (required). Once Rstudio is installed, open it and run the following commands
```
library(shiny)
runGist("943ff5fdbd94815cc27f302d9f56ff0b")
```
This should bring up the app interface. Here you can upload the stratified Rpkm file (in the 4-column format that we generated above) and the metadata file (provided in the test_data folder).

The app has options for collapsing the RPKM table at the desired level of taxonomy and the desired RPKM threshold for visualization.

Clicking on the Sample group nodes will highlight the linkages to the taxonomy nodes and the corresponding function nodes. Hovering over nodes or links will display the underlying rpkm value.

You can also select the format to download the resulting plot (png, pdf or jpeg).
