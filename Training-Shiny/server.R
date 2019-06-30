library(shiny)
require(shinydashboard)
library(ggplot2)
library(dplyr)
library(lubridate)
library(plotly)

getEpochLowerBound <- function() {
  current_date = Sys.Date()
  yesterday = current_date - 1
  previous_monday = floor_date(yesterday, unit="week")+1
  return(as.numeric(as.POSIXct(previous_monday, format="%Y-%m-%d")))
}

fetchActivites <- function() {
  epoch_lb = getEpochLowerBound()
  Activities <- fromJSON(rawToChar(GET(url = paste("https://www.strava.com/api/v3/athlete/activities?after=", epoch_lb, "&per_page=200&access_token=738ba7d3a2a53c870f699ae5a297383eef11f537&page=1", sep = ""))$content))
  return(Activities)
}

shinyServer(function(input, output) {
  Activities = fetchActivites()
  Activities$date = as.Date(substr(Activities$start_date_local, 1 , 10))
  distance = round(sum(Activities$distance/1000), digits = 2)
  output$value1 <- renderValueBox({
    valueBox(
      paste(distance, "km")
      ,"Mileage this week"
      ,icon = icon("stats",lib='glyphicon')
      ,color = "purple")  
  })
  running_time = sum(Activities[Activities$type == 'Run',]$moving_time)
  hours = floor(running_time/3600)
  minutes = round((running_time/3600 - hours)*60)
  output$value2 <- renderValueBox({ 
    valueBox(
      paste(hours, "h", minutes, "m", sep = "")
      ,'Running time this week'
      ,icon = icon("gbp",lib='glyphicon')
      ,color = "green")  
  })
  pace = (running_time/60)/distance
  pace_minutes = floor(pace)
  pace_seconds = round( (pace - pace_minutes)*60 )
  output$value3 <- renderValueBox({
    valueBox(
      paste( pace_minutes, ":", pace_seconds, "/km", sep = "" )
      ,"Average pace this week"
      ,icon = icon("menu-hamburger",lib='glyphicon')
      ,color = "yellow")   
  })
  dates <- seq(floor_date(Sys.Date() - 1, unit="week")+1, floor_date(yesterday, unit="week")+ 7, by = "day")
  output$plot <- renderPlotly({ plot_ly(Activities, 
                                x = ~date, y = ~distance, type = 'bar', 
                                marker = list(color = 'rgba(64,224,208, 0.5)', line = list(color = 'rgb(8,48,107)', width = 1.5))) %>% 
      layout(xaxis = list(title = "Date", range = 1000*c(getEpochLowerBound() - 86400/2, getEpochLowerBound() + 86400*7), type = 'date'),barmode = 'stack') })
})
