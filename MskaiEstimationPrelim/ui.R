library(shiny)
library(DT)

shinyUI(
  fluidPage(style = "width:1500px;",
            titlePanel(paste("Evidence Explorer", if(blind) "***Blinded***" else "")),
            tags$head(tags$style(type = "text/css", "
             #loadmessage {
                                 position: fixed;
                                 top: 0px;
                                 left: 0px;
                                 width: 100%;
                                 padding: 5px 0px 5px 0px;
                                 text-align: center;
                                 font-weight: bold;
                                 font-size: 100%;
                                 color: #000000;
                                 background-color: #ADD8E6;
                                 z-index: 105;
                                 }
                                 ")),
            conditionalPanel(condition = "$('html').hasClass('shiny-busy')",
                             tags$div("Processing...",id = "loadmessage")),
            fluidRow(
              column(3,
                     selectInput("target", "Target", unique(exposureOfInterest$exposureName), selected = unique(exposureOfInterest$exposureName)[1]),
                     selectInput("comparator", "Comparator", unique(exposureOfInterest$exposureName), selected = unique(exposureOfInterest$exposureName)[4]),
                     selectInput("outcome", "Outcome", unique(outcomeOfInterest$outcomeName)),
                     checkboxGroupInput("database", "Data source", database$databaseId, selected = database$databaseId[[1]]),
                     checkboxGroupInput("analysis", "Analysis", cohortMethodAnalysis$description, selected = cohortMethodAnalysis$description[[1]])
              ),
              column(9,
                     dataTableOutput("mainTable"),
                     conditionalPanel("output.rowIsSelected == true",
                                      tabsetPanel(id = "detailsTabsetPanel",
                                                  tabPanel("Power",
                                                           uiOutput("powerTableCaption"),
                                                           tableOutput("powerTable"),
                                                           conditionalPanel("output.isMetaAnalysis == false",
                                                             uiOutput("timeAtRiskTableCaption"),
                                                             tableOutput("timeAtRiskTable")
                                                           )
                                                  ),
                                                  tabPanel("Attrition",
                                                           plotOutput("attritionPlot", width = 600, height = 600),
                                                           uiOutput("attritionPlotCaption"),
                                                           div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                               downloadButton("downloadAttritionPlotPng", label = "Download diagram as PNG"),
                                                               downloadButton("downloadAttritionPlotPdf", label = "Download diagram as PDF")
                                                           )
                                                  ),
                                                  tabPanel("Population characteristics",
                                                           uiOutput("table1Caption"),
                                                           dataTableOutput("table1Table")),
                                                  tabPanel("Propensity model",
                                                           div(strong("Table 3."),"Fitted propensity model, listing all coviates with non-zero coefficients. Positive coefficients indicate predictive of the target exposure."),
                                                           dataTableOutput("propensityModelTable")),
                                                  tabPanel("Propensity scores",
                                                           plotOutput("psDistPlot"),
                                                           div(strong("Figure 2."),"Preference score distribution. The preference score is a transformation of the propensity score
                                                                                                         that adjusts for differences in the sizes of the two treatment groups. A higher overlap indicates subjects in the
                                                                                                         two groups were more similar in terms of their predicted probability of receiving one treatment over the other."),
                                                           div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                               downloadButton("downloadPsDistPlotPng", label = "Download plot as PNG"),
                                                               downloadButton("downloadPsDistPlotPdf", label = "Download plot as PDF")
                                                           )),
                                                  tabPanel("Covariate balance",
                                                           conditionalPanel("output.isMetaAnalysis == false",
                                                             uiOutput("hoverInfoBalanceScatter"),
                                                             plotOutput("balancePlot",
                                                                        hover = hoverOpts("plotHoverBalanceScatter", delay = 100, delayType = "debounce")),
                                                             uiOutput("balancePlotCaption"),
                                                             div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                                 downloadButton("downloadBalancePlotPng", label = "Download plot as PNG"),
                                                                 downloadButton("downloadBalancePlotPdf", label = "Download plot as PDF")
                                                             )),
                                                           conditionalPanel("output.isMetaAnalysis == true",
                                                                            plotOutput("balanceSummaryPlot"),
                                                                            uiOutput("balanceSummaryPlotCaption"),
                                                                            div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                                                downloadButton("downloadBalanceSummaryPlotPng", label = "Download plot as PNG"),
                                                                                downloadButton("downloadBalanceSummaryPlotPdf", label = "Download plot as PDF")
                                                                            ))
                                                           ),
                                                  tabPanel("Systematic error",
                                                           plotOutput("systematicErrorPlot"),
                                                           div(strong("Figure 4."),"Systematic error. Effect size estimates for the negative controls (true hazard ratio = 1)
                                                                                    and positive controls (true hazard ratio > 1), before and after calibration. Estimates below the diagonal dashed
                                                                                    lines are statistically significant (alpha = 0.05) different from the true effect size. A well-calibrated
                                                                                    estimator should have the true effect size within the 95 percent confidence interval 95 percent of times."),
                                                           div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                               downloadButton("downloadSystematicErrorPlotPng", label = "Download plot as PNG"),
                                                               downloadButton("downloadSystematicErrorPlotPdf", label = "Download plot as PDF")
                                                           ),
                                                           conditionalPanel("output.isMetaAnalysis == true",
                                                                            plotOutput("systematicErrorSummaryPlot"),
                                                                            div(strong("Figure 8."),"Fitted null distributions per data source."),
                                                                            div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                                                downloadButton("downloadSystematicErrorSummaryPlotPng", label = "Download plot as PNG"),
                                                                                downloadButton("downloadSystematicErrorSummaryPlotPdf", label = "Download plot as PDF")
                                                                            ))
                                                           ),
                                                  tabPanel("Forest plot",
                                                           plotOutput("forestPlot"),
                                                           uiOutput("forestPlotCaption"),
                                                           div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                               downloadButton("downloadForestPlotPng", label = "Download plot as PNG"),
                                                               downloadButton("downloadForestPlotPdf", label = "Download plot as PDF")
                                                           )),
                                                  tabPanel("Kaplan-Meier",
                                                           plotOutput("kaplanMeierPlot", height = 550),
                                                           uiOutput("kaplanMeierPlotPlotCaption"),
                                                           div(style = "display: inline-block;vertical-align: top;margin-bottom: 10px;",
                                                               downloadButton("downloadKaplanMeierPlotPng", label = "Download plot as PNG"),
                                                               downloadButton("downloadKaplanMeierPlotPdf", label = "Download plot as PDF")
                                                           )),
                                                  tabPanel("Subgroups",
                                                           uiOutput("subgroupTableCaption"),
                                                           dataTableOutput("subgroupTable")
                                                  )
                                                  
                                      )
                     )
              )
              
            )
  )
)
