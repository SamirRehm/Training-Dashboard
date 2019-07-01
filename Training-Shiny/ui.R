library(shiny)
require(shinydashboard)
library(ggplot2)
library(dplyr)

# Define UI for application that draws a histogram
shinyUI(dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody(
    #frow1 <- fluidRow(
    #  tags$head(tags$style(HTML(".small-box {height: 50px}"))),
    #  valueBoxOutput("value1")
    #  ,valueBoxOutput("value2")
    #  ,infoBoxOutput("value3")
    #),
    frow2 <- fluidRow( 
      box(
        title = "Current Week Mileage Breakdown (km)"
        ,status = "primary"
        ,solidHeader = TRUE 
        ,collapsible = TRUE 
        , plotlyOutput("plot", height = '200px')
      )
  ),
  frow3 <- fluidRow (
    box(
      title = "Weekly Mileage (km)"
      ,status = "primary"
      ,solidHeader = TRUE 
      ,collapsible = TRUE 
      , plotlyOutput("runs", height = '200px')
    ),
    box(
      title = "Weekly Active Time (Hours)"
      ,status = "primary"
      ,solidHeader = TRUE 
      ,collapsible = TRUE 
      , plotlyOutput("active_time", height = '200px')
    )
  )
)))
