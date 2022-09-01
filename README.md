# JarrVis
A shiny app for visualizing stratified rpkm output from metagenomic pipelines - JARRVIS (Just Another stRatified Rpkm VISualizer)

<p align="center">
	<img src="images/jarrvis_logo.png?raw=true" alt="Logo" width=65% height=65%>
</p>

This repository provides the source code and the test data files for running the JarrVis app locally.

## Running the app locally in Rstudio
To run this app you would require a local install of Rstudio (R version 3.6) with the shiny package (required). Once Rstudio is installed, open it and run app.R file using the "Run App" button in Rstudio

## Running thru Github Gist from Rstudio

Just run the following commands in Rstudio

```
library(shiny)
runGist("943ff5fdbd94815cc27f302d9f56ff0b")
```

## Navigating the interface
Running the app.R file in Rstudio (either locally or using the Github Gist) should bring up the app interface.

Here you can upload the stratified Rpkm file (in the 4-column format that we generated above) and the metadata file (provided in the test_data folder).

The app has options for collapsing the RPKM table at the desired level of taxonomy and the desired RPKM threshold for visualization.

Once all the parameters are set, you can click on "Display Plot" to generate the Sankey plot.

Right-Clicking on the Sample group nodes will highlight the linkages all the way through to the taxonomy nodes and the corresponding function nodes. Right-clicking on the Function nodes will hightlight the linkages all the way through to taxonomy nodes and the corresponding Sample group nodes.

Left-click and drag the nodes to change their position.

Hovering over nodes or links will display the underlying rpkm value.

You can also select the format to download the resulting plot (png, pdf or jpeg).
