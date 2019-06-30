library(shiny)
require(shinydashboard)
library(ggplot2)
library(dplyr)

# Define UI for application that draws a histogram
shinyUI(dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody(
    frow1 <- fluidRow(
      valueBoxOutput("value1")
      ,valueBoxOutput("value2")
      ,valueBoxOutput("value3")
    ),
    frow2 <- fluidRow( 
      box(
        title = "Mileage breakdown"
        ,status = "primary"
        ,solidHeader = TRUE 
        ,collapsible = TRUE 
        , plotlyOutput("plot", height = '200px')
      )
  )
)))
