
fluidPage(
	title = "NFT Wallet Score",
    useShinyjs(),
	tags$head(
		tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
		tags$link(rel = "icon", href = "fliptrans.png"),
	    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Roboto+Mono"),
	    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Inter")
	),
	tags$head(tags$script(src = "rudderstack.js")),
	tags$style(type="text/css",
		".shiny-output-error { visibility: hidden; }",
		".shiny-output-error:before { visibility: hidden; }"
	),
	withTags({
		header(class="top-banner",
			section(
				a(
					href="https://www.flipsidecrypto.com", 
					target="_blank",
					img(src = "flipside-x-community.svg"),
					onclick = "rudderstack.track('algoconsole-click-flipside-icon')"
				),
				section(
					class="socials",
					a(class="twitter", href="https://twitter.com/flipsidecrypto", target="_blank", "Twitter", onclick = "rudderstack.track('algoconsole-click-twitter-icon')"),
					a(class="linkedin", href="https://www.linkedin.com/company/flipside-crypto", target="_blank", "LinkedIn", onclick = "rudderstack.track('algoconsole-click-linkedin-icon')"),
					a(class="discord", href="https://flipsidecrypto.com/discord", target="_blank", "Discord", onclick = "rudderstack.track('algoconsole-click-discord-icon')"),
					a(href="https://app.flipsidecrypto.com/auth/signup/velocity", target="_blank", "Sign Up", onclick = "rudderstack.track('algoconsole-click-signup-icon')")
				)
			)
		)
	}),
	withTags({
		section(class="hero"
            , div(
                class='img-container'
			    , img(src = 'sol.jpg', width = '200px')
            )
			, h1(
				class="header"
				, "NFT Wallet Score"
			),
                  fluidRow(class = "about", "Built by Flipside Data Science: ",
              class = "purpletext", "@rishispuffs10", a(href = "https://twitter.com/rishispuffs10", target = "_blank", img(src = "twitter.svg", width = "24px", height = "24x")),
              class = "purpletext", "@BlumbergKellen", a(href = "https://twitter.com/BlumbergKellen", target = "_blank", img(src = "twitter.svg", width = "24px", height = "24px")),
             ),
			 p(
                "Use this website to check out your SOL wallet. Look at your top collections,
                 compare yourself to whales and see the fruit of your labors in this wallet 
                 profitability calculator. Just add your address on the box down below."
            )
		)
	}),
  div(
        id = "overviewSection",      
         fluidRow(column(12,  
                           div(class = ".inputtitle", "Enter Your Address"),
                           uiOutput("inputaddy"))
           ), 
                          
    div(
        class = 'toggle-row'
        , div(
            class="toggle-button"
            , actionButton(inputId = "ProfitButton", label = "Wallet Profit/TX's")
        )
        , div(
            class="toggle-button"
            , actionButton(inputId = "CollectionButton", label = "Collections")
        )
        , div(
            class="toggle-button"
            , actionButton(inputId = "WhaleButton", label = "Whale Watch")
        )),
        
        
        div( id = 'ProfitSection'
                  , div(
            class='subtitle'
            , div(" Wallet Profit/TX's")
        ),div(
            fluidRow(
                column(4
                    , class = 'padding-left-0'
                    , div(class='text-box-header', 'HODL $OL')
                    , div(class='text-box', textOutput('total_holds'))
                )
                , column(4
                    , div(class='text-box-header', 'Flipper $OL')
                    , div(class='text-box', textOutput('total_resold'))
                )
                , column(4
                    , class = 'padding-right-0'
                    , div(class='text-box-header', 'Total $OL')
                    , div(class='text-box', textOutput('total_profit'))
                )
            )
        ),  div(
            class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("WaterfallChart of Your Profits"))
                , div(
                    class = "chart"
                    , plotlyOutput("waterfallPlot", height = 420)
                )
            )
        ),     div(
      class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("AREA Profit/Losses based on Type"))
                , div(
                    class = "chart"
                    , plotlyOutput("new_areaPlot", height = 420)
                )
            )
    ),   div(
            fluidRow(
                column(4
                    , class = 'padding-left-0'
                    , div(class='text-box-header', 'First TX')
                    , div(class='text-box', textOutput('first_tx'))
                )
                , column(4
                    , div(class='text-box-header', 'Last TX')
                    , div(class='text-box', textOutput('last_tx'))
                )
                , column(4
                    , class = 'padding-right-0'
                    , div(class='text-box-header', 'Most TX In A Day')
                    , div(class='text-box', textOutput('highest_tx'))
                )
            )
        ), div(
      class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("Transaction Bar Chart"))
                , div(
                    class = "chart"
                    , plotlyOutput("txPlot", height = 420)
                )
            ))
    # ),    div(
    #         class = "chart-container"
    #         , div(
    #             class = "chart-block"
    #             , div(class = "chart-title", span("Wallet's Transaction and Profitability Tracker"))
    #             , div(
    #                 class = "chart table"
    #                 , reactableOutput("tx_table_table" ,height = 420)
    #                 # , plotlyOutput("address_chart", height = 320)
    #             )
    #         )
    #     )





        ),
        div(
        id = "CollectionSection"
        , div(
            class='subtitle'
            , div("Collections")
            # , "Addresses"
        ),    div(
       class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("Profit/Losses based on Collection"))
                , div(
                    class = "chart"
                    , plotlyOutput("profitPlot", height = 420)
                )
            )
        ),

        div(
      class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("Your Top Collections by Volume last 90 Days"))
                , div(
                    class = "chart"
                    , plotlyOutput("top_collectionsPlot", height = 420)
                )
            )
    ),
    div(
      class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("MarketPlace Pie Chart"))
                , div(
                    class = "chart"
                    , plotlyOutput("marketPlot", height = 420)
                )
            )
    ),
    div(
            class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("Diamond Handed NFT's and Your Profits"))
                , div(
                    class = "chart table"
                    , reactableOutput("collections_table" ,height = 420)
                  
                )
            )
        )
        

    
    ),
    div( id = "WhaleSection"
        , div(
            class='subtitle'
            , div("Whale Watch")
            # , "Addresses"
        ), 
        div(
            class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("WHALE WATCH"))
                , div(
                    class = "chart table"
                    , reactableOutput("whales_table" ,height = 420)
                    # , plotlyOutput("address_chart", height = 320)
                )
            )
        ),
          div(
      class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("Top Volume collections of whales"))
                , div(
                    class = "chart"
                    , plotlyOutput("whale_volumePlot", height = 420)
                )
            )
    ),
        div(
      class = "chart-container"
            , div(
                class = "chart-block"
                , div(class = "chart-title", span("Top Profit collections of Whales"))
                , div(
                    class = "chart"
                    , plotlyOutput("whales_collections", height = 420)
                )
            )
    ),
    )





  
))