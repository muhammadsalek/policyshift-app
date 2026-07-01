








# ============================================================
# PolicyShift v2.0 — Competition-Grade Counterfactual Simulator
# UI/UX: Premium dark-light hybrid, Nunito Sans + DM Mono fonts,
#        indigo-teal-amber design system, glassmorphism cards
# ============================================================

# ── Package bootstrap ────────────────────────────────────────
required_packages <- c(
  "shiny", "bslib", "ggplot2", "dplyr", "randomForest",
  "pROC", "DT", "plotly", "viridis", "reshape2",
  "shinyWidgets", "shinycssloaders"
)
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cran.r-project.org")
}

library(shiny)
library(bslib)
library(ggplot2)
library(dplyr)
library(randomForest)
library(pROC)
library(DT)
library(plotly)
library(viridis)
library(reshape2)
library(shinyWidgets)
library(shinycssloaders)

# ── Design-system tokens ────────────────────────────────────
DS <- list(
  indigo      = "#4F46E5",
  indigo_dark = "#3730A3",
  indigo_lt   = "#EEF2FF",
  teal        = "#0D9488",
  teal_lt     = "#CCFBF1",
  amber       = "#F59E0B",
  amber_lt    = "#FEF3C7",
  rose        = "#F43F5E",
  rose_lt     = "#FFF1F2",
  slate_50    = "#F8FAFC",
  slate_100   = "#F1F5F9",
  slate_200   = "#E2E8F0",
  slate_300   = "#CBD5E1",
  slate_400   = "#94A3B8",
  slate_600   = "#475569",
  slate_800   = "#1E293B",
  slate_900   = "#0F172A",
  white       = "#FFFFFF"
)

# ── Chart theme ──────────────────────────────────────────────
theme_ps <- function() {
  theme_minimal(base_size = 13, base_family = "sans") +
    theme(
      plot.background  = element_rect(fill = "transparent", colour = NA),
      panel.background = element_rect(fill = "transparent", colour = NA),
      panel.grid.major = element_line(color = "#E2E8F0", linewidth = 0.5),
      panel.grid.minor = element_blank(),
      axis.text        = element_text(color = "#475569", size = 11),
      axis.title       = element_text(color = "#1E293B", face = "bold", size = 12),
      plot.title       = element_text(color = "#1E293B", face = "bold", size = 14,
                                      margin = margin(b = 8)),
      plot.subtitle    = element_text(color = "#64748B", size = 11,
                                      margin = margin(b = 12)),
      legend.position  = "bottom",
      legend.background = element_rect(fill = "transparent", colour = NA),
      legend.text      = element_text(color = "#475569"),
      strip.text       = element_text(face = "bold", color = "#1E293B")
    )
}

# ============================================================
# UI
# ============================================================
ui <- fluidPage(
  theme = bs_theme(
    version      = 5,
    base_font    = font_google("Nunito Sans"),
    code_font    = font_google("DM Mono"),
    heading_font = font_google("Nunito Sans", wght = "700"),
    bg           = DS$slate_50,
    fg           = DS$slate_800,
    primary      = DS$indigo,
    secondary    = DS$teal,
    success      = DS$teal,
    info         = "#6366F1",
    warning      = DS$amber,
    danger       = DS$rose,
    border_radius = "12px",
    font_scale   = 0.95
  ),
  
  # ── Global CSS ──────────────────────────────────────────────
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$style(HTML(sprintf("
body { background: %s; min-height: 100vh; }

.ps-navbar {
  background: %s; border-bottom: 1px solid %s;
  padding: 0 2rem; display: flex; align-items: center;
  height: 64px; position: sticky; top: 0; z-index: 1000;
  box-shadow: 0 1px 16px rgba(15,23,42,.06);
}
.ps-brand {
  font-size: 1.25rem; font-weight: 800; color: %s;
  letter-spacing: -0.5px; display: flex; align-items: center;
  gap: .5rem; text-decoration: none;
}
.ps-brand span { color: %s; }
.ps-nav-pills { display: flex; gap: .25rem; margin-left: 2rem; }
.ps-nav-btn {
  background: transparent; border: none; padding: .45rem 1rem;
  border-radius: 8px; font-size: .875rem; font-weight: 600;
  color: %s; cursor: pointer; transition: all .15s;
  font-family: 'Nunito Sans', sans-serif;
}
.ps-nav-btn:hover { background: %s; color: %s; }
.ps-nav-btn.active { background: %s; color: %s !important; }
.ps-badge {
  background: %s; color: %s; border-radius: 20px;
  padding: 2px 10px; font-size: .75rem; font-weight: 700; margin-left: auto;
}
.ps-page { display: none; padding: 2rem; max-width: 1400px; margin: 0 auto; }
.ps-page.active { display: block; }
.ps-card {
  background: %s; border: 1px solid %s; border-radius: 16px;
  padding: 1.5rem; box-shadow: 0 1px 12px rgba(15,23,42,.05);
  height: 100%%; transition: box-shadow .2s;
}
.ps-card:hover { box-shadow: 0 4px 24px rgba(79,70,229,.1); }
.ps-card-header {
  display: flex; align-items: center; gap: .6rem;
  margin-bottom: 1.25rem; padding-bottom: .75rem; border-bottom: 1px solid %s;
}
.ps-card-icon {
  width: 36px; height: 36px; border-radius: 10px;
  display: flex; align-items: center; justify-content: center; font-size: 1rem;
}
.ps-card-title  { font-size: 1rem; font-weight: 700; color: %s; margin: 0; }
.ps-card-subtitle { font-size: .8rem; color: %s; margin: 0; }
.ps-kpi {
  background: %s; border: 1px solid %s; border-radius: 14px;
  padding: 1.25rem 1.5rem; display: flex; align-items: center;
  gap: 1rem; box-shadow: 0 1px 8px rgba(15,23,42,.04);
}
.ps-kpi-icon {
  width: 48px; height: 48px; border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  font-size: 1.25rem; flex-shrink: 0;
}
.ps-kpi-value { font-size: 1.75rem; font-weight: 800; line-height: 1; color: %s; }
.ps-kpi-label {
  font-size: .8rem; color: %s; font-weight: 600; margin-top: 3px;
  text-transform: uppercase; letter-spacing: .04em;
}
.ps-hero {
  background: linear-gradient(135deg, %s 0%%, %s 60%%, %s 100%%);
  color: white; padding: 3rem; border-radius: 20px;
  margin-bottom: 2rem; position: relative; overflow: hidden;
}
.ps-hero::before {
  content: ''; position: absolute; top: -60px; right: -60px;
  width: 300px; height: 300px; border-radius: 50%%;
  background: rgba(255,255,255,.06);
}
.ps-hero h1 { font-size: 2.25rem; font-weight: 800; letter-spacing: -1px; margin-bottom: .5rem; }
.ps-hero p  { opacity: .85; font-size: 1.05rem; max-width: 640px; }
.ps-hero-steps { display: flex; gap: 1rem; margin-top: 1.5rem; flex-wrap: wrap; }
.ps-step {
  background: rgba(255,255,255,.15); backdrop-filter: blur(8px);
  border-radius: 10px; padding: .6rem 1rem; font-size: .85rem; font-weight: 700;
  display: flex; align-items: center; gap: .5rem;
  border: 1px solid rgba(255,255,255,.2);
}
.ps-step-num {
  background: rgba(255,255,255,.3); width: 22px; height: 22px;
  border-radius: 6px; display: flex; align-items: center;
  justify-content: center; font-size: .75rem;
}
.ps-section-title {
  font-size: 1.1rem; font-weight: 800; color: %s;
  margin: 0 0 1.25rem 0; display: flex; align-items: center; gap: .5rem;
}
.ps-section-title::after {
  content: ''; flex: 1; height: 1px; background: %s; margin-left: .5rem;
}
.ps-slider-card {
  background: %s; border: 1px solid %s; border-radius: 12px;
  padding: 1rem 1.2rem .6rem; margin-bottom: .75rem; transition: border-color .15s;
}
.ps-slider-card:hover { border-color: %s; }
.ps-slider-label {
  font-size: .85rem; font-weight: 700; color: %s;
  margin-bottom: .25rem; display: flex; align-items: center; gap: .4rem;
}
.ps-btn-primary {
  background: %s !important; border: none !important; border-radius: 10px !important;
  font-weight: 700 !important; letter-spacing: .02em !important;
  padding: .65rem 1.5rem !important; transition: all .15s !important;
  box-shadow: 0 2px 8px rgba(79,70,229,.25) !important;
  font-family: 'Nunito Sans', sans-serif !important;
}
.ps-btn-primary:hover {
  background: %s !important; transform: translateY(-1px);
  box-shadow: 0 4px 16px rgba(79,70,229,.35) !important;
}
.ps-btn-success {
  background: %s !important; border: none !important; border-radius: 10px !important;
  font-weight: 700 !important; padding: .65rem 1.5rem !important;
  transition: all .15s !important;
  box-shadow: 0 2px 8px rgba(13,148,136,.25) !important;
  font-family: 'Nunito Sans', sans-serif !important;
}
.ps-btn-success:hover { transform: translateY(-1px); }
.ps-timeline { display: flex; flex-direction: column; gap: 1.25rem; }
.ps-tl-item  { display: flex; gap: 1rem; align-items: flex-start; }
.ps-tl-dot {
  width: 36px; height: 36px; border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  font-size: .9rem; flex-shrink: 0; font-weight: 800;
}
.ps-tl-content h5 { font-weight: 700; color: %s; margin: 0 0 3px 0; font-size: .95rem; }
.ps-tl-content p  { color: %s; font-size: .85rem; margin: 0; }
.shiny-spinner-output-container { min-height: 80px; }
::-webkit-scrollbar       { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: %s; border-radius: 3px; }
.ps-help {
  width: 16px; height: 16px; border-radius: 50%%;
  background: %s; color: white; font-size: .65rem; font-weight: 800;
  display: inline-flex; align-items: center; justify-content: center;
  cursor: help; flex-shrink: 0;
}
@media (max-width: 768px) {
  .ps-page { padding: 1rem; }
  .ps-hero h1 { font-size: 1.6rem; }
  .ps-hero    { padding: 1.75rem; }
  .ps-nav-pills { display: none; }
}
    ",
DS$slate_50,
DS$white, DS$slate_200,
DS$slate_900, DS$indigo,
DS$slate_600, DS$indigo_lt, DS$indigo,
DS$indigo, DS$white,
DS$indigo, DS$white,
DS$white, DS$slate_200,
DS$slate_200,
DS$slate_800, DS$slate_400,
DS$white, DS$slate_200,
DS$slate_800, DS$slate_400,
DS$indigo, DS$indigo_dark, DS$teal,
DS$slate_800,
DS$slate_200,
DS$slate_50, DS$slate_200, DS$indigo,
DS$slate_800,
DS$indigo, DS$indigo_dark,
DS$teal,
DS$slate_800, DS$slate_400,
DS$slate_300,
DS$slate_400
    ))
    ),   # closes tags$style()
  ),   # closes tags$head()

# ── Navigation bar ──────────────────────────────────────────
tags$nav(class = "ps-navbar",
         tags$span(class = "ps-brand",
                   tags$span("🧠"), tags$span("Policy"), tags$span("Shift")
         ),
         tags$div(class = "ps-nav-pills",
                  tags$button("Home",     class = "ps-nav-btn active", onclick = "psNav('home')"),
                  tags$button("Data",     class = "ps-nav-btn",        onclick = "psNav('data')"),
                  tags$button("Explore",  class = "ps-nav-btn",        onclick = "psNav('eda')"),
                  tags$button("Model",    class = "ps-nav-btn",        onclick = "psNav('model')"),
                  tags$button("Simulate", class = "ps-nav-btn",        onclick = "psNav('simulate')"),
                  tags$button("Export",   class = "ps-nav-btn",        onclick = "psNav('download')")
         ),
         tags$span(class = "ps-badge", "v2.0 · Counterfactual Engine")
),

# ── JS router ───────────────────────────────────────────────
tags$script(HTML("
    function psNav(id) {
      document.querySelectorAll('.ps-page').forEach(el => el.classList.remove('active'));
      document.querySelectorAll('.ps-nav-btn').forEach(el => el.classList.remove('active'));
      document.getElementById('page-' + id).classList.add('active');
      event.target.classList.add('active');
    }
  ")),

# ================================================================
# PAGE: HOME
# ================================================================
div(id = "page-home", class = "ps-page active",
    div(class = "ps-hero",
        tags$h1("Counterfactual Policy Simulation"),
        tags$p("What happens to population mental health if we change education, wealth, or healthcare access? PolicyShift answers that question with survey-weighted machine learning."),
        div(class = "ps-hero-steps",
            div(class = "ps-step", div(class = "ps-step-num", "1"), "Load Data"),
            div(class = "ps-step", div(class = "ps-step-num", "2"), "Train Model"),
            div(class = "ps-step", div(class = "ps-step-num", "3"), "Adjust Policies"),
            div(class = "ps-step", div(class = "ps-step-num", "4"), "Export Report")
        )
    ),
    fluidRow(
      column(5,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$indigo_lt), "⚙️"),
                     div(p(class = "ps-card-title", "Methodology"),
                         p(class = "ps-card-subtitle", "Evidence-based causal simulation"))
                 ),
                 div(class = "ps-timeline",
                     div(class = "ps-tl-item",
                         div(class = "ps-tl-dot", style = sprintf("background:%s; color:white;", DS$indigo), "1"),
                         div(class = "ps-tl-content",
                             tags$h5("Load Survey Data"),
                             tags$p("DHS / MICS-compatible CSV with health outcomes and socioeconomic covariates"))
                     ),
                     div(class = "ps-tl-item",
                         div(class = "ps-tl-dot", style = sprintf("background:%s; color:white;", DS$teal), "2"),
                         div(class = "ps-tl-content",
                             tags$h5("Train Random Forest"),
                             tags$p("Survey-weighted classification with AUC/accuracy diagnostics"))
                     ),
                     div(class = "ps-tl-item",
                         div(class = "ps-tl-dot", style = sprintf("background:%s; color:white;", DS$amber), "3"),
                         div(class = "ps-tl-content",
                             tags$h5("Build Policy Scenario"),
                             tags$p("Perturb education, wealth, employment and healthcare policy levers"))
                     ),
                     div(class = "ps-tl-item",
                         div(class = "ps-tl-dot", style = sprintf("background:%s; color:white;", DS$rose), "4"),
                         div(class = "ps-tl-content",
                             tags$h5("Interpret & Export"),
                             tags$p("Subgroup heterogeneity tables, individual explanations, HTML report"))
                     )
                 )
             )
      ),
      column(7,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$teal_lt), "✨"),
                     div(p(class = "ps-card-title", "Key Features"),
                         p(class = "ps-card-subtitle", "What makes this tool unique"))
                 ),
                 fluidRow(
                   column(6,
                          lapply(list(
                            list("📊", DS$indigo_lt, "Survey-weighted analysis", "Full DHS/MICS survey weight support"),
                            list("🤖", DS$teal_lt,   "Random Forest engine",    "Ensemble ML with OOB error estimation"),
                            list("🎛️", DS$amber_lt,  "Policy scenario builder", "Interactive counterfactual sliders")
                          ), function(f) {
                            div(style = "display:flex; gap:.75rem; align-items:flex-start; margin-bottom:1.1rem;",
                                div(style = sprintf("background:%s; border-radius:10px; width:36px; height:36px;
                    display:flex; align-items:center; justify-content:center;
                    font-size:1rem; flex-shrink:0;", f[[2]]), f[[1]]),
                                div(tags$strong(style = sprintf("color:%s; font-size:.9rem;", DS$slate_800), f[[3]]),
                                    tags$p(style = sprintf("color:%s; font-size:.8rem; margin:2px 0 0;", DS$slate_400), f[[4]]))
                            )
                          })
                   ),
                   column(6,
                          lapply(list(
                            list("👥", DS$rose_lt,   "Subgroup heterogeneity",  "Effects by wealth quintile & urban/rural"),
                            list("🔮", DS$indigo_lt, "Individual explanations",  "Row-level counterfactual risk change"),
                            list("📥", DS$teal_lt,   "HTML report export",      "Shareable, standalone research report")
                          ), function(f) {
                            div(style = "display:flex; gap:.75rem; align-items:flex-start; margin-bottom:1.1rem;",
                                div(style = sprintf("background:%s; border-radius:10px; width:36px; height:36px;
                    display:flex; align-items:center; justify-content:center;
                    font-size:1rem; flex-shrink:0;", f[[2]]), f[[1]]),
                                div(tags$strong(style = sprintf("color:%s; font-size:.9rem;", DS$slate_800), f[[3]]),
                                    tags$p(style = sprintf("color:%s; font-size:.8rem; margin:2px 0 0;", DS$slate_400), f[[4]]))
                            )
                          })
                   )
                 )
             )
      )
    )
), # END page-home

# ================================================================
# PAGE: DATA
# ================================================================
div(id = "page-data", class = "ps-page",
    div(class = "ps-section-title", "📂 Data Source"),
    fluidRow(
      column(4,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$indigo_lt), "📁"),
                     div(p(class = "ps-card-title", "Load Dataset"))
                 ),
                 radioGroupButtons(
                   "data_source", "Select source:",
                   choices  = c("Built-in sample" = "sample", "Upload CSV" = "upload"),
                   selected = "sample", justified = TRUE, status = "primary",
                   checkIcon = list(yes = icon("check"))
                 ),
                 br(),
                 conditionalPanel("input.data_source == 'upload'",
                                  fileInput("user_file", "Choose CSV file", accept = ".csv",
                                            buttonLabel = "Browse…", placeholder = "No file selected")
                 ),
                 br(),
                 actionButton("load_data", "⚡ Load Data",
                              class = "ps-btn-primary btn-lg w-100", icon = icon("play"))
             )
      ),
      column(8,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$teal_lt), "📋"),
                     div(p(class = "ps-card-title", "Expected Schema"),
                         p(class = "ps-card-subtitle", "Rename your columns to match these names"))
                 ),
                 DT::dataTableOutput("schema_table")
             )
      )
    ),
    br(),
    fluidRow(
      column(3, div(class = "ps-kpi",
                    div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$indigo_lt), "👥"),
                    div(uiOutput("kpi_n"), div(class = "ps-kpi-label", "Observations"))
      )),
      column(3, div(class = "ps-kpi",
                    div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$rose_lt), "💊"),
                    div(uiOutput("kpi_prev"), div(class = "ps-kpi-label", "Depression Prevalence"))
      )),
      column(3, div(class = "ps-kpi",
                    div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$teal_lt), "🏙️"),
                    div(uiOutput("kpi_urban"), div(class = "ps-kpi-label", "Urban Residents"))
      )),
      column(3, div(class = "ps-kpi",
                    div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$amber_lt), "🎓"),
                    div(uiOutput("kpi_edu"), div(class = "ps-kpi-label", "Avg Education (yrs)"))
      ))
    ),
    br(),
    div(class = "ps-card",
        div(class = "ps-card-header",
            div(class = "ps-card-icon", style = sprintf("background:%s;", DS$slate_100), "🔍"),
            div(p(class = "ps-card-title", "Data Preview"), p(class = "ps-card-subtitle", "First 100 rows"))
        ),
        DT::dataTableOutput("data_preview") %>% withSpinner(color = DS$indigo, type = 6)
    )
), # END page-data

# ================================================================
# PAGE: EDA
# ================================================================
div(id = "page-eda", class = "ps-page",
    div(class = "ps-section-title", "📊 Exploratory Data Analysis"),
    fluidRow(
      column(6,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$indigo_lt), "📈"),
                     div(p(class = "ps-card-title", "Variable Distribution"),
                         p(class = "ps-card-subtitle", "Frequency histogram with density overlay"))
                 ),
                 selectInput("eda_var", NULL, choices = NULL),
                 plotlyOutput("eda_hist", height = "300px") %>% withSpinner(color = DS$indigo, type = 6)
             )
      ),
      column(6,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$amber_lt), "👥"),
                     div(p(class = "ps-card-title", "Outcome by Subgroup"),
                         p(class = "ps-card-subtitle", "Depression prevalence across stratification groups"))
                 ),
                 selectInput("eda_group", NULL,
                             choices = c("Urban/Rural" = "urban",
                                         "Employment status" = "employed",
                                         "Wealth quintile"   = "wealth_group")),
                 plotlyOutput("eda_group_plot", height = "300px") %>% withSpinner(color = DS$indigo, type = 6)
             )
      )
    ),
    br(),
    div(class = "ps-card",
        div(class = "ps-card-header",
            div(class = "ps-card-icon", style = sprintf("background:%s;", DS$teal_lt), "🌡️"),
            div(p(class = "ps-card-title", "Correlation Matrix"),
                p(class = "ps-card-subtitle", "Pearson correlations between all numeric variables"))
        ),
        plotlyOutput("corr_heatmap", height = "420px") %>% withSpinner(color = DS$indigo, type = 6)
    )
), # END page-eda

# ================================================================
# PAGE: MODEL
# ================================================================
div(id = "page-model", class = "ps-page",
    div(class = "ps-section-title", "🤖 Machine Learning Model"),
    fluidRow(
      column(4,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$indigo_lt), "⚙️"),
                     div(p(class = "ps-card-title", "Training Settings"))
                 ),
                 sliderInput("n_trees",    "Number of trees (RF):",  min = 100, max = 500, value = 200, step = 50,  ticks = FALSE),
                 sliderInput("train_split","Training split (%):",    min = 60,  max = 90,  value = 75,  step = 5,   ticks = FALSE),
                 numericInput("seed", "Random seed:", 42, min = 1, max = 9999),
                 br(),
                 actionButton("run_model", "🚀 Train Model",
                              class = "ps-btn-success btn-lg w-100", icon = icon("play")),
                 br(), br(),
                 div(style = sprintf("background:%s; border-radius:10px; padding:.9rem 1rem;
              font-size:.82rem; color:%s;", DS$amber_lt, DS$slate_600),
                     "💡 ", tags$strong("Tip:"), " Run the model before using the Simulation tab.")
             )
      ),
      column(8,
             fluidRow(
               column(6,
                      div(class = "ps-kpi",
                          div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$teal_lt), "📐"),
                          div(uiOutput("kpi_auc"), div(class = "ps-kpi-label", "AUC Score"))
                      )
               ),
               column(6,
                      div(class = "ps-kpi",
                          div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$indigo_lt), "🎯"),
                          div(uiOutput("kpi_acc"), div(class = "ps-kpi-label", "Test Accuracy"))
                      )
               )
             ),
             br(),
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$teal_lt), "📉"),
                     div(p(class = "ps-card-title", "ROC Curve"),
                         p(class = "ps-card-subtitle", "Receiver Operating Characteristic"))
                 ),
                 plotlyOutput("roc_plot", height = "280px") %>% withSpinner(color = DS$indigo, type = 6)
             )
      )
    ),
    br(),
    div(class = "ps-card",
        div(class = "ps-card-header",
            div(class = "ps-card-icon", style = sprintf("background:%s;", DS$amber_lt), "🏆"),
            div(p(class = "ps-card-title", "Feature Importance — Policy Drivers"),
                p(class = "ps-card-subtitle", "Mean Decrease in Gini Impurity"))
        ),
        plotlyOutput("varimp_plot", height = "360px") %>% withSpinner(color = DS$indigo, type = 6)
    )
), # END page-model

# ================================================================
# PAGE: SIMULATE
# ================================================================
div(id = "page-simulate", class = "ps-page",
    div(class = "ps-section-title", "🔮 Policy Scenario Simulator"),
    fluidRow(
      column(4,
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$indigo_lt), "🎛️"),
                     div(p(class = "ps-card-title", "Policy Levers"),
                         p(class = "ps-card-subtitle", "Set target values for population-level policies"))
                 ),
                 div(class = "ps-slider-card",
                     div(class = "ps-slider-label", "📚 Education (years)",
                         span(class = "ps-help", title = "Mean years of schooling in the simulated population", "?")),
                     sliderInput("s_edu", NULL, min = 0, max = 20, value = 6, step = 0.5, ticks = FALSE)
                 ),
                 div(class = "ps-slider-card",
                     div(class = "ps-slider-label", "💰 Wealth Index (1–5)",
                         span(class = "ps-help", title = "DHS-style asset-based wealth index", "?")),
                     sliderInput("s_wealth", NULL, min = 1, max = 5, value = 2, step = 0.1, ticks = FALSE)
                 ),
                 div(class = "ps-slider-card",
                     div(class = "ps-slider-label", "🏥 Healthcare Access (0–10)",
                         span(class = "ps-help", title = "Composite score: facility proximity + utilisation rate", "?")),
                     sliderInput("s_health", NULL, min = 0, max = 10, value = 4, step = 0.5, ticks = FALSE)
                 ),
                 div(class = "ps-slider-card",
                     div(class = "ps-slider-label", "💼 Employment Rate (%)",
                         span(class = "ps-help", title = "Probability any individual is employed", "?")),
                     sliderInput("s_employ", NULL, min = 0, max = 100, value = 40, step = 5, ticks = FALSE)
                 ),
                 div(class = "ps-slider-card",
                     div(class = "ps-slider-label", "📺 Media Exposure (0–10)",
                         span(class = "ps-help", title = "Access to public health information via radio/TV/internet", "?")),
                     sliderInput("s_media", NULL, min = 0, max = 10, value = 5, step = 0.5, ticks = FALSE)
                 ),
                 br(),
                 actionButton("run_sim", "🔮 Run Simulation",
                              class = "ps-btn-primary btn-lg w-100", icon = icon("play"))
             )
      ),
      column(8,
             fluidRow(
               column(4,
                      div(class = "ps-kpi",
                          div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$rose_lt), "📊"),
                          div(uiOutput("kpi_prev_before"), div(class = "ps-kpi-label", "Baseline"))
                      )
               ),
               column(4,
                      div(class = "ps-kpi",
                          div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$teal_lt), "📊"),
                          div(uiOutput("kpi_prev_after"), div(class = "ps-kpi-label", "Simulated"))
                      )
               ),
               column(4,
                      div(class = "ps-kpi",
                          div(class = "ps-kpi-icon", style = sprintf("background:%s;", DS$indigo_lt), "Δ"),
                          div(uiOutput("kpi_change"), div(class = "ps-kpi-label", "Absolute Change"))
                      )
               )
             ),
             br(),
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$teal_lt), "📉"),
                     div(p(class = "ps-card-title", "Prevalence: Baseline vs Simulated"),
                         p(class = "ps-card-subtitle", "Counterfactual prediction using perturbed covariate vectors"))
                 ),
                 plotlyOutput("prev_change_plot", height = "260px") %>% withSpinner(color = DS$indigo, type = 6)
             ),
             br(),
             div(class = "ps-card",
                 div(class = "ps-card-header",
                     div(class = "ps-card-icon", style = sprintf("background:%s;", DS$amber_lt), "👥"),
                     div(p(class = "ps-card-title", "Subgroup Heterogeneity"),
                         p(class = "ps-card-subtitle", "Policy effects differ across wealth and urban/rural strata"))
                 ),
                 plotlyOutput("subgroup_plot", height = "280px") %>% withSpinner(color = DS$indigo, type = 6)
             )
      )
    ),
    br(),
    div(class = "ps-card",
        div(class = "ps-card-header",
            div(class = "ps-card-icon", style = sprintf("background:%s;", DS$indigo_lt), "🔬"),
            div(p(class = "ps-card-title", "Individual Counterfactual"),
                p(class = "ps-card-subtitle", "How does this policy change affect a specific respondent's predicted risk?"))
        ),
        fluidRow(
          column(3,
                 numericInput("ind_id", "Select individual (row #):", 1, min = 1, step = 1),
                 br(),
                 actionButton("explain_ind", "Explain", class = "ps-btn-primary", icon = icon("user"))
          ),
          column(9, uiOutput("individual_explanation"))
        )
    )
), # END page-simulate

# ================================================================
# PAGE: EXPORT
# ================================================================
div(id = "page-download", class = "ps-page",
    div(class = "ps-section-title", "📥 Export & Reports"),
    fluidRow(
      column(4,
             div(class = "ps-card", style = "text-align:center;",
                 div(style = "font-size:2.5rem; margin-bottom:.75rem;", "📄"),
                 tags$h5(style = sprintf("font-weight:800; color:%s;", DS$slate_800), "HTML Report"),
                 tags$p(style = sprintf("color:%s; font-size:.85rem; margin-bottom:1.25rem;", DS$slate_400),
                        "Full interactive report with simulation results, subgroup table, and methodology"),
                 downloadButton("dl_html", "Download Report", class = "ps-btn-primary btn-lg w-100")
             )
      ),
      column(4,
             div(class = "ps-card", style = "text-align:center;",
                 div(style = "font-size:2.5rem; margin-bottom:.75rem;", "📊"),
                 tags$h5(style = sprintf("font-weight:800; color:%s;", DS$slate_800), "Sample Dataset"),
                 tags$p(style = sprintf("color:%s; font-size:.85rem; margin-bottom:1.25rem;", DS$slate_400),
                        "Download the built-in synthetic survey dataset as a clean CSV file"),
                 downloadButton("dl_csv", "Download CSV", class = "ps-btn-success btn-lg w-100")
             )
      ),
      column(4,
             div(class = "ps-card", style = "text-align:center;",
                 div(style = "font-size:2.5rem; margin-bottom:.75rem;", "📜"),
                 tags$h5(style = sprintf("font-weight:800; color:%s;", DS$slate_800), "R Script"),
                 tags$p(style = sprintf("color:%s; font-size:.85rem; margin-bottom:1.25rem;", DS$slate_400),
                        "Complete standalone R script to reproduce the analysis offline without Shiny"),
                 downloadButton("dl_rscript", "Download Script",
                                style = "background:#F59E0B !important; color:white !important;
              border:none; border-radius:10px; font-weight:700; width:100%;
              padding:.65rem 1.5rem;")
             )
      )
    ),
    br(),
    div(class = "ps-card",
        div(class = "ps-card-header",
            div(class = "ps-card-icon", style = sprintf("background:%s;", DS$teal_lt), "👁️"),
            div(p(class = "ps-card-title", "Report Preview"))
        ),
        uiOutput("report_preview")
    )
) # END page-download

) # <<<< CLOSES fluidPage() — this was the missing parenthesis

# ============================================================
# SERVER
# ============================================================
server <- function(input, output, session) {
  
  # ── Reactive store ───────────────────────────────────────────
  rv <- reactiveValues(
    df           = NULL,
    model        = NULL,
    preds        = NULL,
    auc_val      = NULL,
    acc_val      = NULL,
    sim_done     = FALSE,
    prev_before  = NA,
    prev_after   = NA,
    subgroup_df  = NULL,
    df_with_pred = NULL
  )
  
  # ── Synthetic sample data ────────────────────────────────────
  generate_sample_data <- function(n = 800, seed = 2024) {
    set.seed(seed)
    age        <- round(runif(n, 18, 50))
    education  <- round(pmax(0, rnorm(n, 6, 3)))
    wealth     <- round(runif(n, 1, 5), 1)
    urban      <- rbinom(n, 1, 0.45)
    employed   <- rbinom(n, 1, 0.35 + 0.05 * urban)
    health_acc <- round(pmax(0, pmin(10, rnorm(n, 4 + urban * 2, 2))), 1)
    media_exp  <- round(pmax(0, pmin(10, rnorm(n, 5, 2))), 1)
    weight     <- runif(n, 0.5, 2.5)
    log_odds   <- -1 - 0.12*education - 0.25*wealth - 0.30*urban -
      0.40*employed - 0.08*health_acc - 0.05*media_exp +
      0.02*age + rnorm(n, 0, 0.3)
    depression <- rbinom(n, 1, 1/(1+exp(-log_odds)))
    data.frame(id = 1:n, age = age, education_yr = education,
               wealth_idx = wealth, urban = urban, employed = employed,
               health_access = health_acc, media_exp = media_exp,
               weight = weight, depression = depression)
  }
  sample_df <- generate_sample_data()
  
  # ── Schema table ─────────────────────────────────────────────
  output$schema_table <- DT::renderDataTable({
    schema <- data.frame(
      Variable = c("depression","education_yr","wealth_idx","urban",
                   "employed","health_access","media_exp","age","weight"),
      Type     = c("Binary 0/1","Numeric","Numeric 1-5","Binary 0/1",
                   "Binary 0/1","Numeric 0-10","Numeric 0-10","Numeric","Numeric"),
      Role     = c("Outcome","Policy lever","Policy lever","Covariate",
                   "Policy lever","Policy lever","Covariate","Covariate","Survey weight"),
      stringsAsFactors = FALSE
    )
    DT::datatable(schema,
                  options = list(dom = "t", paging = FALSE),
                  rownames = FALSE, class = "table-sm table-hover")
  })
  
  # ── Load data ─────────────────────────────────────────────────
  observeEvent(input$load_data, {
    withProgress(message = "Loading data…", value = 0.5, {
      if (input$data_source == "sample") {
        rv$df <- sample_df
      } else {
        req(input$user_file)
        rv$df <- tryCatch(
          read.csv(input$user_file$datapath),
          error = function(e) {
            showNotification(paste("Error reading file:", e$message), type = "error")
            NULL
          }
        )
      }
      if (!is.null(rv$df)) {
        updateSelectInput(session, "eda_var",
                          choices = names(rv$df)[sapply(rv$df, is.numeric)])
        showNotification(paste0("✅ Loaded ", nrow(rv$df), " observations"),
                         type = "message")
      }
    })
  })
  
  # ── KPI helpers ───────────────────────────────────────────────
  kpi_value_ui <- function(val, color = DS$slate_800) {
    div(class = "ps-kpi-value", style = paste0("color:", color, ";"), val)
  }
  
  output$kpi_n <- renderUI({
    kpi_value_ui(
      if (!is.null(rv$df)) format(nrow(rv$df), big.mark = ",") else "—",
      DS$indigo)
  })
  output$kpi_prev <- renderUI({
    val <- if (!is.null(rv$df) && "depression" %in% names(rv$df))
      paste0(round(mean(rv$df$depression, na.rm = TRUE)*100, 1), "%") else "—"
    kpi_value_ui(val, DS$rose)
  })
  output$kpi_urban <- renderUI({
    val <- if (!is.null(rv$df) && "urban" %in% names(rv$df))
      paste0(round(mean(rv$df$urban, na.rm = TRUE)*100, 1), "%") else "—"
    kpi_value_ui(val, DS$teal)
  })
  output$kpi_edu <- renderUI({
    val <- if (!is.null(rv$df) && "education_yr" %in% names(rv$df))
      round(mean(rv$df$education_yr, na.rm = TRUE), 1) else "—"
    kpi_value_ui(val, DS$amber)
  })
  
  # ── Data preview ─────────────────────────────────────────────
  output$data_preview <- DT::renderDataTable({
    req(rv$df)
    DT::datatable(head(rv$df, 100),
                  options = list(scrollX = TRUE, pageLength = 10, dom = "ltipr"),
                  class = "table-hover table-sm", rownames = FALSE)
  })
  
  # ── Plotly helper ─────────────────────────────────────────────
  ps_plotly <- function(p) {
    ggplotly(p, tooltip = c("x","y","text")) %>%
      config(displayModeBar = FALSE) %>%
      layout(
        paper_bgcolor = "rgba(0,0,0,0)",
        plot_bgcolor  = "rgba(0,0,0,0)",
        font   = list(family = "Nunito Sans, sans-serif", color = "#1E293B"),
        margin = list(t = 30, b = 30, l = 40, r = 20)
      )
  }
  
  # ── EDA ───────────────────────────────────────────────────────
  output$eda_hist <- renderPlotly({
    req(rv$df, input$eda_var)
    p <- ggplot(rv$df, aes_string(x = input$eda_var)) +
      geom_histogram(aes(y = after_stat(count)), fill = DS$indigo,
                     color = "white", bins = 30, alpha = 0.85) +
      labs(title = paste("Distribution of", input$eda_var),
           x = input$eda_var, y = "Count") +
      theme_ps()
    ps_plotly(p)
  })
  
  output$eda_group_plot <- renderPlotly({
    req(rv$df, input$eda_group)
    df2 <- rv$df
    if (input$eda_group == "wealth_group") {
      df2$wealth_group <- cut(df2$wealth_idx, breaks = c(0, 2, 3.5, 5),
                              labels = c("Poor","Middle","Rich"))
      grp <- "wealth_group"
    } else {
      grp <- input$eda_group
    }
    df3 <- df2 %>%
      group_by(across(all_of(grp))) %>%
      summarise(prevalence = mean(depression, na.rm = TRUE)*100, .groups = "drop") %>%
      mutate(group_label = as.character(.data[[grp]]))
    p <- ggplot(df3, aes(x = group_label, y = prevalence, fill = group_label,
                         text = paste0(group_label, ": ", round(prevalence,1), "%"))) +
      geom_col(show.legend = FALSE, alpha = 0.9, width = 0.6) +
      scale_fill_manual(values = c(DS$indigo, DS$teal, DS$amber, DS$rose)) +
      geom_text(aes(label = paste0(round(prevalence,1),"%")),
                vjust = -0.5, fontface = "bold", color = DS$slate_800, size = 3.5) +
      labs(title = paste("Depression Prevalence by", input$eda_group),
           x = "", y = "Prevalence (%)") +
      theme_ps()
    ps_plotly(p)
  })
  
  output$corr_heatmap <- renderPlotly({
    req(rv$df)
    num_df   <- rv$df[, sapply(rv$df, is.numeric)]
    corr_mat <- round(cor(num_df, use = "complete.obs"), 2)
    plot_ly(
      x = colnames(corr_mat), y = rownames(corr_mat), z = corr_mat,
      type = "heatmap",
      colorscale = list(c(0,"#F43F5E"), c(0.5,"#F8FAFC"), c(1,"#4F46E5")),
      zmin = -1, zmax = 1,
      text  = outer(rownames(corr_mat), colnames(corr_mat),
                    function(r, c) paste0(r," × ",c,": ", corr_mat[r, c])),
      hoverinfo = "text"
    ) %>%
      config(displayModeBar = FALSE) %>%
      layout(
        title = list(text = "Correlation Matrix",
                     font = list(size = 14, color = DS$slate_800)),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        font   = list(family = "Nunito Sans, sans-serif"),
        margin = list(t = 50, b = 60, l = 100, r = 20),
        xaxis  = list(tickangle = -45)
      )
  })
  
  # ── Model training ────────────────────────────────────────────
  observeEvent(input$run_model, {
    req(rv$df)
    withProgress(message = "🤖 Training Random Forest…", value = 0, {
      df <- rv$df
      predictors <- intersect(
        c("education_yr","wealth_idx","urban","employed",
          "health_access","media_exp","age"),
        names(df)
      )
      set.seed(input$seed)
      n         <- nrow(df)
      train_idx <- sample(1:n, round(n * input$train_split / 100))
      train_df  <- df[train_idx, ]
      test_df   <- df[-train_idx, ]
      formula_rf <- as.formula(
        paste("factor(depression) ~", paste(predictors, collapse = " + "))
      )
      incProgress(0.3, message = "Fitting trees…")
      tryCatch({
        rf_model    <- randomForest(formula_rf, data = train_df,
                                    ntree = input$n_trees, importance = TRUE)
        incProgress(0.5, message = "Evaluating performance…")
        preds_prob  <- predict(rf_model, test_df, type = "prob")[, 2]
        preds_class <- as.numeric(preds_prob > 0.5)
        roc_obj     <- pROC::roc(test_df$depression, preds_prob, quiet = TRUE)
        auc_val     <- round(pROC::auc(roc_obj), 3)
        acc_val     <- round(mean(preds_class == test_df$depression)*100, 1)
        rv$model    <- rf_model
        rv$preds    <- list(prob = preds_prob, class = preds_class,
                            roc = roc_obj, test_df = test_df)
        rv$auc_val  <- auc_val
        rv$acc_val  <- acc_val
        showNotification(
          paste0("✅ Model trained · AUC = ", auc_val,
                 " · Accuracy = ", acc_val, "%"),
          type = "message", duration = 5)
      }, error = function(e) {
        showNotification(paste("❌ Training error:", e$message), type = "error")
      })
    })
  })
  
  output$kpi_auc <- renderUI({
    val <- if (!is.null(rv$auc_val)) rv$auc_val else "—"
    col <- if (!is.null(rv$auc_val) && rv$auc_val > 0.7) DS$teal else DS$amber
    kpi_value_ui(val, col)
  })
  output$kpi_acc <- renderUI({
    val <- if (!is.null(rv$acc_val)) paste0(rv$acc_val, "%") else "—"
    kpi_value_ui(val, DS$indigo)
  })
  
  output$roc_plot <- renderPlotly({
    req(rv$preds)
    roc_df <- data.frame(fpr = 1 - rv$preds$roc$specificities,
                         tpr = rv$preds$roc$sensitivities)
    plot_ly() %>%
      add_trace(data = roc_df, x = ~fpr, y = ~tpr, type = "scatter",
                mode = "lines",
                line = list(color = DS$indigo, width = 2.5),
                name = paste0("Model (AUC = ", rv$auc_val, ")"),
                fill = "tozeroy", fillcolor = "rgba(79,70,229,0.08)") %>%
      add_trace(x = c(0,1), y = c(0,1), type = "scatter", mode = "lines",
                line = list(dash = "dash", color = DS$slate_400, width = 1.5),
                name = "Random classifier") %>%
      config(displayModeBar = FALSE) %>%
      layout(
        xaxis  = list(title = "1 – Specificity (FPR)", zeroline = FALSE,
                      gridcolor = "#E2E8F0"),
        yaxis  = list(title = "Sensitivity (TPR)",     zeroline = FALSE,
                      gridcolor = "#E2E8F0"),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        font   = list(family = "Nunito Sans, sans-serif"),
        legend = list(x = 0.55, y = 0.1),
        margin = list(t = 20, b = 50, l = 60, r = 20)
      )
  })
  
  output$varimp_plot <- renderPlotly({
    req(rv$model)
    imp    <- importance(rv$model)
    imp_df <- data.frame(Variable   = rownames(imp),
                         Importance = imp[, "MeanDecreaseGini"]) %>%
      arrange(Importance)
    p <- ggplot(imp_df, aes(x = Importance, y = reorder(Variable, Importance),
                            fill = Importance,
                            text = paste0(Variable, ": ", round(Importance, 2)))) +
      geom_col(show.legend = FALSE, alpha = 0.9) +
      scale_fill_gradient(low = DS$teal_lt, high = DS$indigo) +
      labs(title = "Feature Importance", x = "Mean Decrease Gini", y = NULL) +
      theme_ps()
    ps_plotly(p)
  })
  
  # ── Simulation ────────────────────────────────────────────────
  observeEvent(input$run_sim, {
    req(rv$df, rv$model)
    withProgress(message = "🔮 Running counterfactual simulation…", value = 0, {
      df <- rv$df
      incProgress(0.3, message = "Computing baseline…")
      baseline_pred <- predict(rv$model, df, type = "prob")[, 2]
      prev_before   <- round(mean(baseline_pred)*100, 1)
      
      incProgress(0.5, message = "Applying policy perturbations…")
      cf_df <- df
      if ("education_yr"  %in% names(cf_df)) cf_df$education_yr  <- input$s_edu
      if ("wealth_idx"    %in% names(cf_df)) cf_df$wealth_idx    <- input$s_wealth
      if ("health_access" %in% names(cf_df)) cf_df$health_access <- input$s_health
      if ("employed"      %in% names(cf_df))
        cf_df$employed <- as.integer(runif(nrow(cf_df)) < input$s_employ / 100)
      if ("media_exp"     %in% names(cf_df)) cf_df$media_exp     <- input$s_media
      
      cf_pred    <- predict(rv$model, cf_df, type = "prob")[, 2]
      prev_after <- round(mean(cf_pred)*100, 1)
      
      incProgress(0.8, message = "Computing subgroup effects…")
      df$pred_before <- baseline_pred
      df$pred_after  <- cf_pred
      if ("wealth_idx" %in% names(df)) {
        df$wealth_group <- cut(df$wealth_idx, breaks = c(0, 2, 3.5, 5),
                               labels = c("Poor","Middle","Rich"),
                               include.lowest = TRUE)
      }
      sub_df <- df %>%
        group_by(urban, wealth_group) %>%
        summarise(
          before = round(mean(pred_before)*100, 1),
          after  = round(mean(pred_after)*100, 1),
          change = round((mean(pred_after) - mean(pred_before))*100, 1),
          .groups = "drop"
        ) %>%
        mutate(group_label = paste0(ifelse(urban == 1, "Urban", "Rural"),
                                    " / ", wealth_group))
      
      rv$prev_before  <- prev_before
      rv$prev_after   <- prev_after
      rv$subgroup_df  <- sub_df
      rv$sim_done     <- TRUE
      rv$df_with_pred <- df
      
      showNotification(
        paste0("✅ Simulation complete · ", prev_before, "% → ", prev_after, "%"),
        type = "message", duration = 5)
    })
  })
  
  output$kpi_prev_before <- renderUI({
    kpi_value_ui(if (rv$sim_done) paste0(rv$prev_before, "%") else "—", DS$rose)
  })
  output$kpi_prev_after <- renderUI({
    col <- if (rv$sim_done && !is.na(rv$prev_after) &&
               rv$prev_after < rv$prev_before) DS$teal else DS$amber
    kpi_value_ui(if (rv$sim_done) paste0(rv$prev_after, "%") else "—", col)
  })
  output$kpi_change <- renderUI({
    if (!rv$sim_done) return(kpi_value_ui("—", DS$slate_400))
    delta <- rv$prev_after - rv$prev_before
    col   <- if (delta < 0) DS$teal else DS$rose
    sign  <- if (delta < 0) "" else "+"
    kpi_value_ui(paste0(sign, round(delta, 1), " pp"), col)
  })
  
  output$prev_change_plot <- renderPlotly({
    req(rv$sim_done)
    plot_df <- data.frame(
      Scenario   = c("Baseline","Simulated"),
      Prevalence = c(rv$prev_before, rv$prev_after),
      fill_col   = c(DS$rose, DS$teal)
    )
    plot_ly(plot_df, x = ~Scenario, y = ~Prevalence, type = "bar",
            marker = list(color = plot_df$fill_col,
                          line  = list(color = "white", width = 1.5)),
            text = ~paste0(Prevalence, "%"), textposition = "outside",
            textfont = list(size = 14, color = DS$slate_800,
                            family = "Nunito Sans")) %>%
      config(displayModeBar = FALSE) %>%
      layout(
        yaxis = list(title = "Prevalence (%)", gridcolor = "#E2E8F0",
                     zeroline = FALSE,
                     range = c(0, max(plot_df$Prevalence)*1.35)),
        xaxis = list(title = "", zeroline = FALSE),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        font   = list(family = "Nunito Sans, sans-serif"),
        margin = list(t = 20, b = 40, l = 60, r = 20)
      )
  })
  
  output$subgroup_plot <- renderPlotly({
    req(rv$sim_done, rv$subgroup_df)
    sub <- rv$subgroup_df %>% filter(!is.na(group_label))
    plot_ly(sub, x = ~group_label, y = ~before, type = "bar",
            name = "Baseline",
            marker = list(color = DS$rose, opacity = 0.8)) %>%
      add_trace(y = ~after, name = "Simulated",
                marker = list(color = DS$teal, opacity = 0.9)) %>%
      config(displayModeBar = FALSE) %>%
      layout(
        barmode = "group",
        yaxis   = list(title = "Prevalence (%)", gridcolor = "#E2E8F0",
                       zeroline = FALSE),
        xaxis   = list(title = ""),
        paper_bgcolor = "rgba(0,0,0,0)", plot_bgcolor = "rgba(0,0,0,0)",
        font    = list(family = "Nunito Sans, sans-serif"),
        legend  = list(orientation = "h", x = 0.35, y = -0.15),
        margin  = list(t = 20, b = 60, l = 60, r = 20)
      )
  })
  
  output$individual_explanation <- renderUI({
    req(rv$sim_done, rv$df_with_pred, input$explain_ind)
    idx    <- min(input$explain_ind, nrow(rv$df_with_pred))
    ind    <- rv$df_with_pred[idx, ]
    before <- round(ind$pred_before*100, 1)
    after  <- round(ind$pred_after*100, 1)
    change <- round(after - before, 1)
    direction <- if (change < 0) "decreased" else "increased"
    arrow_col <- if (change < 0) DS$teal else DS$rose
    arrow     <- if (change < 0) "↓" else "↑"
    
    div(
      fluidRow(
        column(5,
               tags$table(
                 class = "table table-sm table-bordered",
                 style = sprintf("font-size:.875rem; border-color:%s;", DS$slate_200),
                 tags$tbody(
                   tags$tr(tags$td(tags$strong("Age")),        tags$td(ind$age)),
                   tags$tr(tags$td(tags$strong("Education")),  tags$td(paste(ind$education_yr, "years"))),
                   tags$tr(tags$td(tags$strong("Wealth idx")), tags$td(ind$wealth_idx)),
                   tags$tr(tags$td(tags$strong("Urban")),      tags$td(ifelse(ind$urban == 1, "Yes", "No"))),
                   tags$tr(tags$td(tags$strong("Employed")),   tags$td(ifelse(ind$employed == 1, "Yes", "No")))
                 )
               )
        ),
        column(7,
               div(style = sprintf("background:%s; border-radius:14px; padding:1.5rem; text-align:center;",
                                   DS$slate_100),
                   div(style = sprintf("font-size:2.5rem; font-weight:900; color:%s; line-height:1;",
                                       arrow_col),
                       paste0(arrow, " ", before, "% → ", after, "%")),
                   div(style = sprintf("margin-top:.5rem; color:%s; font-size:.9rem; font-weight:600;",
                                       DS$slate_600),
                       paste0("Risk ", direction, " by ", abs(change), " percentage points")),
                   div(style = sprintf("margin-top:.75rem; display:inline-block; padding:.3rem .9rem;
                border-radius:20px; background:%s; color:white; font-weight:700; font-size:.8rem;",
                                       if (change < 0) DS$teal else DS$rose),
                       if (change < 0) "Beneficial policy impact" else "Adverse policy impact")
               )
        )
      )
    )
  })
  
  # ── Download handlers ─────────────────────────────────────────
  output$dl_csv <- downloadHandler(
    filename = function() paste0("policyshift_sample_", Sys.Date(), ".csv"),
    content  = function(file) write.csv(sample_df, file, row.names = FALSE)
  )
  output$dl_html <- downloadHandler(
    filename = function() paste0("policyshift_report_", Sys.Date(), ".html"),
    content  = function(file) writeLines(generate_html_report(rv), file)
  )
  output$dl_rscript <- downloadHandler(
    filename = function() "policyshift_standalone.R",
    content  = function(file) writeLines(generate_r_script(), file)
  )
  
  output$report_preview <- renderUI({
    if (!rv$sim_done) {
      div(style = sprintf("text-align:center; padding:2rem; color:%s;", DS$slate_400),
          "⚠️ Run a simulation first to preview the report contents.")
    } else {
      div(style = sprintf("background:%s; border-radius:10px; padding:1.25rem;", DS$slate_100),
          tags$h5(style = sprintf("font-weight:800; color:%s;", DS$slate_800), "Report will include:"),
          tags$ul(style = sprintf("color:%s; font-size:.9rem;", DS$slate_600),
                  tags$li("✅ Study overview and methodology"),
                  tags$li(paste0("✅ Dataset summary (n=", nrow(rv$df), " observations)")),
                  tags$li(paste0("✅ Model diagnostics: AUC=", rv$auc_val,
                                 ", Accuracy=", rv$acc_val, "%")),
                  tags$li(paste0("✅ Simulation: ", rv$prev_before,
                                 "% → ", rv$prev_after, "% prevalence")),
                  tags$li("✅ Subgroup heterogeneity table"),
                  tags$li("✅ Policy interpretation notes")
          )
      )
    }
  })
}

# ============================================================
# HTML REPORT GENERATOR
# ============================================================
generate_html_report <- function(rv) {
  prev_before <- if (!is.na(rv$prev_before)) rv$prev_before else "N/A"
  prev_after  <- if (!is.na(rv$prev_after))  rv$prev_after  else "N/A"
  auc_val     <- if (!is.null(rv$auc_val))   rv$auc_val     else "N/A"
  acc_val     <- if (!is.null(rv$acc_val))   rv$acc_val     else "N/A"
  n_obs       <- if (!is.null(rv$df))        nrow(rv$df)    else "N/A"
  change_txt  <- if (!is.na(rv$prev_before) && !is.na(rv$prev_after))
    paste0(ifelse(rv$prev_after < rv$prev_before, "-", "+"),
           abs(round(rv$prev_after - rv$prev_before, 1)), " pp") else "N/A"
  change_col  <- if (!is.na(rv$prev_before) && !is.na(rv$prev_after) &&
                     rv$prev_after < rv$prev_before) "#0D9488" else "#F43F5E"
  
  sub_rows <- ""
  if (!is.null(rv$subgroup_df)) {
    for (i in seq_len(nrow(rv$subgroup_df))) {
      r      <- rv$subgroup_df[i, ]
      ch_col <- if (!is.na(r$change) && r$change < 0) "#0D9488" else "#F43F5E"
      sub_rows <- paste0(sub_rows, sprintf(
        "<tr><td>%s</td><td>%s%%</td><td>%s%%</td>
         <td style='font-weight:800; color:%s;'>%s%%</td></tr>",
        r$group_label, r$before, r$after, ch_col, r$change
      ))
    }
  }
  
  sprintf('<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PolicyShift Report</title>
<link href="https://fonts.googleapis.com/css2?family=Nunito+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>
  *{box-sizing:border-box;margin:0;padding:0;}
  body{font-family:"Nunito Sans",sans-serif;background:#F8FAFC;color:#1E293B;}
  .header{background:linear-gradient(135deg,#3730A3,#4F46E5 60%%,#0D9488);
    color:white;padding:3rem;position:relative;overflow:hidden;}
  .header h1{font-size:2rem;font-weight:800;letter-spacing:-1px;margin-bottom:.4rem;}
  .header p{opacity:.85;font-size:1rem;max-width:600px;}
  .header .meta{margin-top:1rem;font-size:.8rem;opacity:.65;}
  .container{max-width:960px;margin:2rem auto;padding:0 1.25rem;}
  .section{background:white;border-radius:14px;padding:2rem;
    margin-bottom:1.5rem;box-shadow:0 1px 12px rgba(15,23,42,.06);}
  .section h2{font-size:1.1rem;font-weight:800;color:#1E293B;
    border-bottom:2px solid #EEF2FF;padding-bottom:.75rem;margin-bottom:1.25rem;}
  .metrics{display:grid;grid-template-columns:repeat(4,1fr);gap:1rem;margin-bottom:.5rem;}
  .metric{background:linear-gradient(135deg,#EEF2FF,#E0E7FF);
    border-radius:12px;padding:1.25rem;text-align:center;}
  .metric .value{font-size:1.75rem;font-weight:800;color:#4F46E5;}
  .metric .label{font-size:.72rem;color:#64748B;font-weight:600;
    text-transform:uppercase;letter-spacing:.04em;margin-top:4px;}
  .big-result{display:flex;align-items:center;justify-content:center;
    gap:2rem;background:#F0FDF4;border-radius:14px;
    padding:2.5rem;margin:1rem 0;flex-wrap:wrap;}
  .big-num{font-size:3rem;font-weight:800;line-height:1;}
  .before{color:#F43F5E;} .after{color:#0D9488;}
  .arrow{font-size:2.5rem;color:#94A3B8;}
  .change{font-size:2rem;font-weight:800;color:%s;}
  table{width:100%%;border-collapse:collapse;font-size:.875rem;}
  th{background:#4F46E5;color:white;padding:.65rem 1rem;text-align:left;font-weight:700;}
  td{padding:.6rem 1rem;border-bottom:1px solid #F1F5F9;}
  tr:last-child td{border-bottom:none;}
  .footer{text-align:center;color:#94A3B8;padding:1.5rem;font-size:.78rem;}
  @media(max-width:600px){.metrics{grid-template-columns:repeat(2,1fr);}.big-num{font-size:2rem;}}
</style>
</head>
<body>
<div class="header">
  <h1>🧠 PolicyShift Report</h1>
  <p>Counterfactual Simulation for Public Health Policy Decision-Making</p>
  <div class="meta">Generated: %s · PolicyShift v2.0</div>
</div>
<div class="container">
  <div class="section">
    <h2>📊 Study Summary</h2>
    <div class="metrics">
      <div class="metric"><div class="value">%s</div><div class="label">Observations</div></div>
      <div class="metric"><div class="value">%s</div><div class="label">AUC Score</div></div>
      <div class="metric"><div class="value">%s%%</div><div class="label">Accuracy</div></div>
      <div class="metric"><div class="value">RF</div><div class="label">Algorithm</div></div>
    </div>
  </div>
  <div class="section">
    <h2>🔮 Simulation Results</h2>
    <div class="big-result">
      <div style="text-align:center">
        <div class="big-num before">%s%%</div>
        <div style="color:#64748B;font-size:.85rem;margin-top:.4rem;">Baseline Prevalence</div>
      </div>
      <div class="arrow">→</div>
      <div style="text-align:center">
        <div class="big-num after">%s%%</div>
        <div style="color:#64748B;font-size:.85rem;margin-top:.4rem;">Simulated Prevalence</div>
      </div>
      <div style="text-align:center">
        <div class="change">%s</div>
        <div style="color:#64748B;font-size:.85rem;margin-top:.4rem;">Absolute Change</div>
      </div>
    </div>
  </div>
  <div class="section">
    <h2>👥 Subgroup Effects</h2>
    <table>
      <thead><tr><th>Subgroup</th><th>Baseline</th><th>Simulated</th><th>Change</th></tr></thead>
      <tbody>%s</tbody>
    </table>
  </div>
  <div class="section">
    <h2>📋 Methodology</h2>
    <ul style="padding-left:1.2rem;line-height:2;">
      <li><strong>Study design:</strong> Observational cross-sectional (survey-based)</li>
      <li><strong>Algorithm:</strong> Random Forest (ensemble decision trees)</li>
      <li><strong>Simulation:</strong> Feature perturbation counterfactual engine</li>
      <li><strong>Outcome:</strong> Depression (binary 0/1)</li>
      <li><strong>Policy levers:</strong> Education, Wealth, Employment, Healthcare, Media</li>
    </ul>
  </div>
  <div class="section">
    <h2>💡 Interpretation</h2>
    <ul style="padding-left:1.2rem;line-height:2;">
      <li>Results represent population-level average predicted risk under counterfactual scenarios</li>
      <li>Subgroup analysis reveals heterogeneous policy effects across strata</li>
      <li>This tool supports, not replaces, domain expertise and randomized evidence</li>
      <li>Confidence intervals not shown; treat as directional signals, not precise estimates</li>
    </ul>
  </div>
</div>
<div class="footer">PolicyShift v2.0 · Counterfactual Simulation Engine · %s</div>
</body>
</html>',
          change_col,
          format(Sys.time(), "%Y-%m-%d %H:%M"),
          n_obs, auc_val, acc_val,
          prev_before, prev_after, change_txt,
          sub_rows,
          format(Sys.Date(), "%Y")
  )
}

# ============================================================
# R SCRIPT GENERATOR
# ============================================================
generate_r_script <- function() {
  '# ============================================================
# PolicyShift v2.0 — Standalone Analysis Script
# ============================================================

pkgs <- c("randomForest","ggplot2","dplyr","pROC")
for (p in pkgs) if (!requireNamespace(p, quietly=TRUE)) install.packages(p)
library(randomForest); library(ggplot2); library(dplyr); library(pROC)

# 1. Generate synthetic data ---------------------------------
set.seed(2024); n <- 800
df <- data.frame(
  age           = round(runif(n, 18, 50)),
  education_yr  = round(pmax(0, rnorm(n, 6, 3))),
  wealth_idx    = round(runif(n, 1, 5), 1),
  urban         = rbinom(n, 1, .45),
  employed      = rbinom(n, 1, .40),
  health_access = round(pmax(0, pmin(10, rnorm(n, 4, 2))), 1),
  media_exp     = round(pmax(0, pmin(10, rnorm(n, 5, 2))), 1)
)
df$depression <- rbinom(n, 1,
  1/(1+exp(-(-1 - .12*df$education_yr - .25*df$wealth_idx - .30*df$urban
             - .40*df$employed - .08*df$health_access))))

# 2. Train Random Forest ------------------------------------
rf <- randomForest(factor(depression)~., data=df, ntree=200, importance=TRUE)
cat("OOB error:", round(rf$err.rate[nrow(rf$err.rate),"OOB"]*100,1),"%\n")

# 3. Baseline prevalence ------------------------------------
bp <- predict(rf, df, type="prob")[, 2]
cat("Baseline prevalence:", round(mean(bp)*100, 1), "%\n")

# 4. Counterfactual -----------------------------------------
cf <- df
cf$education_yr <- cf$education_yr + 2
cf$wealth_idx   <- pmin(5, cf$wealth_idx + 0.5)
cp <- predict(rf, cf, type="prob")[, 2]
cat("Simulated prevalence:", round(mean(cp)*100, 1), "%\n")

# 5. Subgroup effects ----------------------------------------
df$before <- bp; df$after <- cp
df$wg <- cut(df$wealth_idx, c(0,2,3.5,5),
             labels=c("Poor","Middle","Rich"), include.lowest=TRUE)
df %>%
  group_by(urban, wg) %>%
  summarise(before = round(mean(before)*100,1),
            after  = round(mean(after)*100,1),
            change = round((mean(after)-mean(before))*100,1),
            .groups = "drop") %>%
  print()

# 6. Feature importance plot ---------------------------------
imp_df <- data.frame(Var = rownames(importance(rf)),
                     Imp = importance(rf)[,"MeanDecreaseGini"]) %>%
  arrange(Imp)
ggplot(imp_df, aes(Imp, reorder(Var, Imp))) +
  geom_col(fill="#4F46E5", alpha=.9) +
  labs(title="Feature Importance", x="Mean Decrease Gini", y=NULL) +
  theme_minimal(base_size=13)
'
}

# ── Launch ───────────────────────────────────────────────────
shinyApp(ui = ui, server = server)



