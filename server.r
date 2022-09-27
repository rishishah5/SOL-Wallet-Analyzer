function(input, output,session) {


   


     color_func <- colorRampPalette(c('#00ba38','#ff1100'))
     COLOR_1  <- '#00ba38'
     COLOR_2 <- '#ff1100'


     updateLayout <- function(fig, y.axis.title, tickprefix, showlegend = TRUE, rangemode = "tozero", barmode = 'stack', tickformat = NULL, hoverformat = ",.0f") {
		fig <- fig %>% layout(
			showlegend = showlegend
			, barmode = barmode
			, margin = list(
				b = 0,
				l = 80,
				pad = 30
			)
			, xaxis = list(
				title = ""
				, showgrid = FALSE
				, font = list(family = "Inter")
				, color = "#919EAB"
				, gridcolor = "#637381"
				, rangeslider = list(visible = F)
				, tickformat="%b %d"
			)
			, yaxis= list(
				title = list(
					text = y.axis.title,
					standoff = 30
				)
				, color = "#919EAB"
				, gridcolor = "#637381"
				, rangemode = rangemode
				, tickprefix = tickprefix
				, tickformat = tickformat
				, hoverformat = hoverformat
			)
			, plot_bgcolor = plotly.style$plot_bgcolor
			, paper_bgcolor = plotly.style$paper_bgcolor
			, legend = list(font = list(color = 'white'))
		) %>%
		plotly::config(displayModeBar = FALSE) %>%
		plotly::config(modeBarButtonsToRemove = c("zoomIn2d", "zoomOut2d"))
		return(fig)
	}

	renderFig <- function(dt, x.val, y.val, color, x.axis.title, y.axis.title, type, mode, tickprefix="", fill = NULL, stackgroup = NULL, tickformat=NULL, hoverformat = ",.0f") {
		mode <- ifelse( type == 'box', NULL, mode )
		barmode <- ifelse( type == 'box', NULL, 'stack' )
		colors <- color_func(length(unique(dt[, get(color)])))

		if( type %in% c('box','bar') ) {
			fig <- plot_ly(
				data = dt,
				x = ~get(x.val),
				y = ~get(y.val),
				type = type,
				stackgroup = stackgroup,
				color = ~get(color),
				alpha = 1,
				opacity = 1,
				fill = fill,
				colors = colors
			)
		} else {
			fig <- plot_ly(
				data = dt,
				x = ~get(x.val),
				y = ~get(y.val),
				type = type,
				mode = mode,
				stackgroup = stackgroup,
				color = ~get(color),
				alpha = 1,
				opacity = 1,
				fill = fill,
				colors = colors
			)
		}
		fig <- updateLayout(fig, y.axis.title, tickprefix, tickformat=tickformat, barmode = barmode, hoverformat = hoverformat)
		return(fig)
	}



    formatNum <- function(num) {
        if (num < 1000000) {
            return(format(num, big.mark=',', nsmall=0, digits=3))
        } else if (num < 1000000000) {
            return(paste0(format(num / 1000000, big.mark=',', nsmall=0, digits=3),'M'))
        } else {
            return(paste0(format(num / 1000000000, big.mark=',', nsmall=0, digits=3),'B'))
        }
    }


   output$total_holds <- renderText({
     profit_selected <- profit[people %in% eval(input$addy)]
     if (nrow(profit_selected) > 0) {
            t <- formatNum(profit_selected$holds)
        }
     paste0(t)
    })

       output$total_resold <- renderText({
           profit_selected2 <- profit[people %in% eval(input$addy)]
     if (nrow(profit_selected2) > 0) {
            t <- formatNum(profit_selected2$resold)
        }
     paste0(t)
    })



   output$total_profit <- renderText({
     profit_selected3 <- profit[people %in% eval(input$addy)]
     if (nrow(profit_selected3) > 0) {
            t <- formatNum(profit_selected3$total)
        }
     paste0(t)
    })
   



  output$profitPlot <- renderPlotly({
     rishi <- rishi[purchaser %in% eval(input$addy)]
     rishi$type <- ifelse(rishi$reselling_money_made < 0, "below", "above")
     fig <- plot_ly(
          data = rishi,
          x = rishi$reselling_money_made,
          y = rishi$label,
          type = "bar",
          color = ~type == 'below', colors = c('#00ba38', '#ff1100')
  )

      fig <- updateLayout(fig,'Collection Profit','', showlegend = FALSE, rangemode = "tozero", barmode ='stack',tickformat = '', hoverformat = '' )
    
})

output$inputaddy <- renderUI({
    url.addy <- parseQueryString(session$clientData$url_search)
    
    if(length(url.addy) > 0) {
      default.addy <- names(url.addy)[1]
    } else {
      default.addy <- 'DeoGugXHAjiwTDmM5ab3b1RMZqZPZEzgGjb9aQG15Cwc'
    }
    
    if(is.na(default.addy)) {
      textInput(inputId = "addy", 
                label = NULL,
                width = "100%",
                placeholder = "a SOL wallet address")
    } else {
      textInput(inputId = "addy", 
                label = NULL,
                width = "100%",
                value = '5JiRY4c8YgH1aJCBrWj5gvxv2GF55FKZ3WedJ9rjxGGB')  
    }
  })

  observeEvent(input$addy, {
print(input$addy)
  })


  
output$waterfallPlot <-renderPlotly({
    table <- table[purchaser %in% eval(input$addy)]
     fig <- plot_ly(
  table, name = "20", type = "waterfall",
  x = table$date,textposition = "outside", y= table$money,
  connector = list(line = list(color= "rgb(63, 63, 63)"))) 
fig <- fig %>%
  layout(title = " ",
         xaxis = list(title = ""),
         yaxis = list(title = ""),
         autosize = TRUE,
         showlegend = TRUE)
 fig <- updateLayout(fig,'Title of Waterfall Profit','', showlegend = FALSE, rangemode = "tozero", barmode ='stack',tickformat = '', hoverformat = '' )
     
})
file.location <-   "resold.RData"
load(file.location)

output$new_areaPlot <- renderPlotly({
     resold <- resold[seller %in% eval(input$addy)]
     held_mints <- held_mints[purchaser %in% eval(input$addy)]
     held_nfts <- held_nfts[purchaser %in% eval(input$addy)]
     fig <- plot_ly(x = ~resold$date, y = ~resold$resold_p, type = 'scatter', mode = 'lines', name = 'Profit From Reselling', fill = 'tozeroy',
               fillcolor = '#8aff7a',
               line = list(width = 0.5))
fig <- fig %>% add_trace(x = ~held_nfts$date, y = ~held_nfts$held_nfts_p, name = "NFT's value", fill = 'tozeroy',
                         fillcolor = '#7accff')
fig <- fig %>% add_trace(x = ~held_mints$date, y = ~held_mints$held_mints_p, name = "Minted NFT's value", fill = 'tozeroy',
                         fillcolor = '#ff88fb')
fig <- updateLayout(fig,'Money in SOL','', showlegend = TRUE, rangemode = "tozero", barmode ='stack',tickformat = '', hoverformat = '' )

})

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



output$first_tx <- renderText({
     transactions <- transactions[person %in% eval(input$addy)]
     if (nrow(profit) > 0) {
            t <- formatNum(transactions$first_day)
        }
     paste0(t)
    })
output$last_tx <- renderText({
     transactions <- transactions[person %in% eval(input$addy)]
     if (nrow(profit) > 0) {
            t <- formatNum(transactions$most_recent)
        }
     paste0(t)
    })
output$highest_tx <- renderText({
     transactions <- transactions[person %in% eval(input$addy)]
     if (nrow(profit) > 0) {
            t <- formatNum(transactions$highest_txs_in_a_day)
        }
     paste0(t)
    })

output$txPlot <- renderPlotly({
     calendar <- calendar[person %in% eval(input$addy)]
     fig <- plot_ly(
          data = calendar,
          x = calendar$days,
          y = calendar$txs,
          type = "bar",
          color =I('#00ba38')
  )

      fig <- updateLayout(fig,'Transactions','', showlegend = FALSE, rangemode = "tozero", barmode ='',tickformat = '', hoverformat = '' )
    
})

# output$tx_table_table <- renderReactable({
#         data <- tx_table[purchaser %in% eval(input$addy)]
#         data <- data[, list(date, purchaser, type, label,floor_price,bought_for,profit)]

# 		reactable(
#             data
# 			# , defaultColDef = colDef(
# 			# 	headerStyle = list(background = "#10151A")
# 			# )
# 			, borderless = TRUE
# 			, filterable = TRUE
# 			, outlined = FALSE
# 			, columns = list(
# 				date = colDef(name = "Date", align = "left")
# 				, purchaser = colDef(name = "Your Wallet", align = "left")
# 				, type = colDef(name = "Type of Transaction", align = "left")
# 				, label = colDef(name = "Collection Name", align = "left")
#                     ,floor_price = colDef(name = "Floor or Sold Price(depends on type)", align = "left")
#                     ,bought_for = colDef(name = "Mint/Bought For Price", align = "left")
#                     ,profit = colDef(name = "Profit!!!!", align = "left")
# 			)
# 			, searchable = TRUE
# 	    )
# 	})

output$marketPlot <- renderPlotly({
     filtered_market <- market[purchaser %in% eval(input$addy)]
     colors <- c('#B7FFBF','#95F985','#4DED30','#26D701','#00C301','#00AB08')
fig <- plot_ly(data = filtered_market, labels = ~marketplace, values = ~number, type = 'pie',textposition = 'inside',
        textinfo = 'label+percent',
marker = list(colors = colors,
                      line = list(color = '#FFFFFF', width = 1)),
                      #The 'pull' attribute can also be used to create space between the sectors
        showlegend = FALSE)

 fig <- updateLayout(fig,'Markets','', showlegend = FALSE, rangemode = "tozero", barmode ='',tickformat = '', hoverformat = '' )






})

output$collections_table <- renderReactable({
     data <- collections[purchaser %in% eval(input$addy)]
     data <- data[, list(image,label,date,type,floor_price,bought_for,profit)]

     reactable(
          data 
          , borderless = TRUE
			, filterable = TRUE
			, outlined = FALSE
			, columns = list(
				image = colDef(name = "NFT Image",cell = embed_img(), align = "left")
				, label = colDef(name = "Label", align = "left")
				, date = colDef(name = "Date", align = "left")
				, type = colDef(name = "Tyoe", align = "left")
                    ,floor_price = colDef(name = "Floor or Sold Price(depends on type)", align = "left")
                    ,bought_for = colDef(name = "Mint/Bought For Price", align = "left")
                    ,profit = colDef(name = "Profit!!!!", align = "left")
			)




     )







})
embed_img <- function(data,
                      height = 72,
                      width = 72,
                      horizontal_align = "center",
                      label = NULL,
                      label_position = "right") {

  '%notin%' <- Negate('%in%')

  if (label_position %notin% c("left", "right", "above", "below") == TRUE) {

    stop("label_position must be either 'left', 'right', 'above', 'below'")
  }

  if (!is.null(horizontal_align) && horizontal_align %notin% c("left", "right", "center") == TRUE) {

    stop("horizontal_align must be either 'left', 'right', or 'center'")
  }

  # assign horizontal align
  if (horizontal_align == "left") {

    horizontal_align_css <- "flex-start"

  } else if (horizontal_align == "right") {

    horizontal_align_css <- "flex-end"

  } else horizontal_align_css <- "center"

  image <- function(value, index, name) {

    if (!is.character(value)) return(value)

    if (is.null(value) || is.na(value) || value == "NA" || value == "na" || stringr::str_detect(value, " ")) return("")

    if (grepl("https|http", value) == FALSE) {

      stop("must provide valid link to image.")
    }

    image <- htmltools::img(src = value, align = "center", height = height, width = width)

    if (!is.null(label) & label_position == "right") {

      col_label <- sprintf("     %s", data[[index, label]])

      htmltools::tagList(htmltools::div(style = list(display = "flex", justifyContent = horizontal_align_css),
                                        image, col_label))

    } else if (!is.null(label) & label_position == "left") {

      col_label <- sprintf("%s     ", data[[index, label]])

      htmltools::tagList(htmltools::div(style = list(display = "flex", justifyContent = horizontal_align_css),
                                        col_label, image))

    } else if (!is.null(label) & label_position == "below") {

      col_label <- sprintf("%s", data[[index, label]])

      htmltools::tagList(
        htmltools::div(style = list(display = "flex", justifyContent = horizontal_align_css),
                      image),
        htmltools::div(style = list(textAlign = "center"),
                      col_label))

    } else if (!is.null(label) & label_position == "above") {

      col_label <- sprintf("%s", data[[index, label]])

      htmltools::tagList(
        htmltools::div(style = list(textAlign = "center"),
                       col_label),
        htmltools::div(style = list(display = "flex", justifyContent = horizontal_align_css),
                       image))

    } else htmltools::tagList(htmltools::div(style = list(display = "flex", justifyContent = horizontal_align_css),
                              image))
  }
}




output$whales_table <- renderReactable({
        data <- whales
        data <- data[, list(people, mints_value, secondary_bought_holds, resold_profits,total)]

		reactable(
            data
			# , defaultColDef = colDef(
			# 	headerStyle = list(background = "#10151A")
			# )
			, borderless = TRUE
			, filterable = FALSE
			, outlined = TRUE
			, columns = list(
				people = colDef(name = "Wallet", align = "left")
				, mints_value = colDef(name = "Minted NFT's Value", align = "left")
				, secondary_bought_holds = colDef(name = "Other Held NFT's", align = "left")
				, resold_profits = colDef(name = "Flipped NFT's Profit", align = "left")
                    ,total = colDef(name = "Total Profit)", align = "left")
			)
			, searchable = FALSE
	    )
	})

output$top_collectionsPlot <- renderPlotly({
     top_collections <- top_collections[purchaser %in% eval(input$addy) ]
     fig <- plot_ly(
          data = top_collections,
          x = top_collections$label,
          y = top_collections$volume,
          type = "bar",
          color =I('#00ba38')
  )

      fig <- updateLayout(fig,'Transactions','', showlegend = FALSE, rangemode = "tozero", barmode ='',tickformat = '', hoverformat = '' )
    
})

output$whale_volumePlot <-renderPlotly({

     fig <- plot_ly(
          data = whale_transactions,
          x = whale_transactions$label,
          y = whale_transactions$volume,
          type = "bar",
          color =I('#00ba38')
  )

      fig <- updateLayout(fig,'Transactions','', showlegend = FALSE, rangemode = "tozero", barmode ='',tickformat = '', hoverformat = '' )
    

})
output$whales_collections <- renderPlotly({
     fig <- plot_ly() 
fig <- fig %>%
  add_trace(
     data = whales_collections,
  type = "funnel",
  y = whales_collections$label,
  x = whales_collections$percent) 
     fig <- updateLayout(fig,'Top Whales Involvment in a Collection','', showlegend = FALSE, rangemode = "tozero", barmode ='',tickformat = '', hoverformat = '' )
})


  observeEvent(input$ProfitButton, {
        if(input$ProfitButton %% 2 == 1){
            shinyjs::hide(id = "ProfitSection")
            shinyjs::addClass(id = "ProfitButton", "unselected")
        } else{
            shinyjs::show(id = "ProfitSection")
            shinyjs::removeClass(id = "ProfitButton", "unselected")
        }
    })
    observeEvent(input$CollectionButton, {
        if(input$CollectionButton %% 2 == 1){
            shinyjs::hide(id = "CollectionSection")
            shinyjs::addClass(id = "CollectionButton", "unselected")
        } else{
            shinyjs::show(id = "CollectionSection")
            shinyjs::removeClass(id = "CollectionButton", "unselected")
        }
    })

    observeEvent(input$WhaleButton, {
        if(input$WhaleButton %% 2 == 1){
            shinyjs::hide(id = "WhaleSection")
            shinyjs::addClass(id = "WhaleButton", "unselected")
        } else{
            shinyjs::show(id = "WhaleSection")
            shinyjs::removeClass(id = "WhaleButton", "unselected")
        }
    })


}
