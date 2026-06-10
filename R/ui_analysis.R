analysis_ui <- function(app_data) {
  fluidPage(
    div(
      class = "page-header",
      h2("資料分析"),
      p("從主客場現象出發，逐步拆解勝率與得分之間的關係。")
    ),
    div(
      class = "analysis-flow",
      div(
        class = "analysis-step",
        div(class = "step-kicker", "Raw Data Observation"),
        h3("主場勝率較高，但主場得分反而較低"),
        p("先用比賽原始清理資料觀察大方向：如果主場勝率高，直覺上主場得分也應該更高；但目前資料呈現出相反的現象。"),
        fluidRow(
          column(width = 4, div(class = "metric-card", span("主場勝率"), strong(textOutput("home_win_rate", inline = TRUE)), div(class = "metric-sub", "home win rate"))),
          column(width = 4, div(class = "metric-card", span("客場勝率"), strong(textOutput("away_win_rate", inline = TRUE)), div(class = "metric-sub", "away win rate"))),
          column(width = 4, div(class = "metric-card highlight", span("主場得分差距"), strong(textOutput("home_run_gap", inline = TRUE)), div(class = "metric-sub", "主場平均得分 - 客場平均得分")))
        ),
        div(class = "chart-grid two-cols",
          div(class = "section-block", h3("主客場勝率"), plotOutput("home_away_win_rate_plot", height = 280)),
          div(class = "section-block", h3("主客場平均得失分差"), plotOutput("home_away_run_diff_plot", height = 280))
        ),
        div(class = "section-block", h3("主客場整體摘要"), tableOutput("home_away_summary_table"))
      ),
      div(
        class = "analysis-step",
        div(class = "step-kicker", "Key Moment Analysis"),
        h3("初步拆解：主場勝率與平均得分為何分離？"),
        p("為了解釋主場勝率較高、但平均得分沒有同步提高，我們先檢查兩個方向：主場是否更常拿下小分差比賽，以及客場平均得分是否受到高得分場次拉高。"),
        fluidRow(
          column(width = 3, div(class = "metric-card", span("1 分差主場勝率"), strong(textOutput("one_run_home_win_rate", inline = TRUE)), div(class = "metric-sub", "close game"))),
          column(width = 3, div(class = "metric-card", span("1 分差客場勝率"), strong(textOutput("one_run_away_win_rate", inline = TRUE)), div(class = "metric-sub", "close game"))),
          column(width = 3, div(class = "metric-card highlight", span("主場 9+ 分比例"), strong(textOutput("home_high_score_share", inline = TRUE)), div(class = "metric-sub", "9+ run games"))),
          column(width = 3, div(class = "metric-card highlight", span("客場 9+ 分比例"), strong(textOutput("away_high_score_share", inline = TRUE)), div(class = "metric-sub", "9+ run games")))
        ),
        div(class = "chart-grid two-cols",
          div(class = "section-block", h3("小分差比賽主客場勝率"), plotOutput("close_game_win_rate_plot", height = 280)),
          div(class = "section-block", h3("主客場得分分布"), plotOutput("score_distribution_plot", height = 280))
        ),
        div(
          class = "section-block insight-block",
          h3("計算驗證"),
          p(textOutput("one_run_win_rate_gap_note", inline = TRUE)),
          p(textOutput("high_score_gap_note", inline = TRUE)),
          p("綜合來看，主場勝率與平均得分分離，可能是「主場較會拿下關鍵小分差比賽」與「客場較容易出現高得分場次」共同造成。不過這仍是初步線索，後續需要再拆到局數、比分狀態與後攻情境。")
        )
      )
    )
  )
}
