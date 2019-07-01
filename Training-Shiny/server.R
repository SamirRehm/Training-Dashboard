library(shiny)
require(shinydashboard)
library(ggplot2)
library(dplyr)
library(plyr)
library(lubridate)
library(plotly)
library(jsonlite)
library(httr)

getEpochLowerBound <- function() {
  current_date = Sys.Date()
  yesterday = current_date - 1
  previous_monday = floor_date(yesterday, unit="week")+1 - 105
  return(as.numeric(as.POSIXct(previous_monday, format="%Y-%m-%d")))
}

getPreviousMondayEpoch <- function() {
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

setTypes <- function(RActivites) {
  RActivites$type[grep('soccer', RActivites$name, ignore.case = TRUE)] = 'Soccer'
  RActivites$type[grep('tennis', RActivites$name, ignore.case = TRUE)] = 'Tennis'
  RActivites$type[grep('elliptical', RActivites$name, ignore.case = TRUE)] = 'Elliptical'
  RActivites$type[grep('stationary bike', RActivites$name, ignore.case = TRUE)] = 'Stationary Bike'
  RActivites$type[grep('volleyball', RActivites$name, ignore.case = TRUE)] = 'Volleyball'
  return(RActivites)
}

shinyServer(function(input, output) {
  all_activities = fetchActivites()
  all_activities$date = as.Date(substr(all_activities$start_date_local, 1 , 10))
  all_activities$week = floor_date(all_activities$date - 1, unit="week")+1
  all_activities = all_activities[all_activities$week >= floor_date(Sys.Date() -1, unit="week")+1 - 105,]
  all_activities = setTypes(all_activities)
  Activities = all_activities[all_activities$week == floor_date(Sys.Date() - 1, unit="week")+1,]
  distance = round(sum(Activities$distance/1000), digits = 2)
  running_time = sum(Activities[Activities$type == 'Run',]$moving_time)
  hours = floor(running_time/3600)
  minutes = round((running_time/3600 - hours)*60)
  pace = (running_time/60)/distance
  pace_minutes = floor(pace)
  pace_seconds = round( (pace - pace_minutes)*60 )
  output$plot <- renderPlotly({ plot_ly(Activities, 
                                x = ~date, y = ~round(distance/1000, digits = 2), type = 'bar',
                                marker = list(color = 'rgba(64,224,208, 0.5)', line = list(color = 'rgb(8,48,107)', width = 1.5))) %>% 
      layout(margin = list(l=0, r=0, b=0, t=20), title = paste("Mileage: ", distance, "km      Time: ", hours, "h", minutes, "m      Avg. Pace: ", pace_minutes, ":", pace_seconds, "/km", sep = ""), 
             xaxis = list(title = "", range = 1000*c(getPreviousMondayEpoch() - 86400/2, getPreviousMondayEpoch() + 86400*7), type = 'date'),
             yaxis = list(title = ""),
             barmode = 'stack', font = list(size = 9)) })
  
  distancePerWeek = aggregate(all_activities$distance, by=list(Week=all_activities$week), FUN=sum)
  output$runs = plotly::renderPlotly({
    plot_ly(data = distancePerWeek, x=~Week, y=~x/1000, type='bar', marker = list(color = 'rgba(64,224,208, 0.5)', line = list(color = 'rgb(8,48,107)', width = 1.5))) %>%
      layout(margin = list(l=0, r=0, b=0, t=0), xaxis = list(title = ""), yaxis = list(title = ""), font = list(size = 9))
  })
  
  timePerWeek = aggregate(all_activities$moving_time, by=list(Week=all_activities$week, Type = all_activities$type), FUN=sum)
  runTypes = c('Run', 'Soccer', 'Elliptical', 'Swim', 'Volleyball', 'Tennis', 'Workout')
  colours = c('rgba(160,70, 255,0.6)', 'rgba(100,255,100,0.6)', 'rgba(255, 100, 100, 0.6)', 'rgba(255, 255, 100, 0.6)',
              'rgba(255, 100, 255, 0.6)', 'rgba(50, 150, 255, 0.6)', 'rgba(100, 255, 255, 0.6)')
  names = c('Warm-up', 'Intervals', 'Tempo Run', 'Fartlek', 'Long Run', 'Easy Run', 'Cool-down')
  p <- plot_ly(data = timePerWeek, type = "bar", hoverinfo = "all") %>% layout(margin = list(l=0, r=0, b=0, t=0), xaxis = list(title = ""), barmode='stack', font = list(size = 9))
  for(i in 1:length(runTypes)) {
    runsOfType = timePerWeek
    runsOfType = transform(runsOfType, x = ifelse(Type == runTypes[[i]], x, 0))
    if(nrow(runsOfType) > 0) {
      p <- p %>% add_trace (p, x=~Week, y=runsOfType$x/3600, type='bar',
                            marker = list(line = list(color = 'rgb(8,48,107)', width = 1.5), 
                                          color = colours[[i]]),  name = runTypes[[i]])
    }
  }
  output$active_time = renderPlotly({
    p
  })
  
})
