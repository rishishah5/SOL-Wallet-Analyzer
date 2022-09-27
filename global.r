library(data.table)
library(shiny)
library(ggplot2)
library(tools)
library(plotly)
library(shinyBS)
library(shinyjs)
library(dplyr)
library(htmlwidgets)
library(reactable)
library(stringr)



  file.location <-   "rishi.RData"
   load(file.location)
  file.location <-   "profit.RData"
  load(file.location)
    file.location <-   "table.RData"
  load(file.location)
  file.location <-   "held_nfts.RData"
load(file.location)
file.location <-   "held_mints.RData"
load(file.location)
file.location <-   "transactions.RData"
load(file.location)
file.location <-   "calendar.RData"
load(file.location)
# file.location <-   "tx_table.RData"
# load(file.location)
file.location <-   "market.RData"
load(file.location)
file.location <-   "collections.RData"
load(file.location)
file.location <-   "whales.RData"
load(file.location)
file.location <-   "top_collections.RData"
load(file.location)
file.location <-   "whales_collections.RData"
load(file.location)
file.location <-   "whale_transactions.RData"
load(file.location)

plotly.style <- list(
  plot_bgcolor = "rgba(0, 0, 0, 0)", 
  paper_bgcolor = "rgba(0, 0, 0, 0)"
)



