analysis_server <- function(input, output, session, app_data) {
  overall_summary <- reactive({
    req(app_data$analysis[["主客場整體摘要"]])
    app_data$analysis[["主客場整體摘要"]]
  })

  close_game_summary <- reactive({
    req(app_data$analysis[["小分差勝率摘要"]])
    app_data$analysis[["小分差勝率摘要"]]
  })

  score_distribution_summary <- reactive({
    req(app_data$analysis[["得分分布摘要"]])
    app_data$analysis[["得分分布摘要"]]
  })

  score_quantile_summary <- reactive({
    req(app_data$analysis[["得分分位數摘要"]])
    app_data$analysis[["得分分位數摘要"]]
  })

  ninth_inning_context_summary <- reactive({
    req(app_data$analysis[["第九局進攻機會摘要"]])
    app_data$analysis[["第九局進攻機會摘要"]]
  })

  one_run_phase_summary <- reactive({
    req(app_data$analysis[["一分差階段摘要"]])
    app_data$analysis[["一分差階段摘要"]]
  })

  one_run_state_after_six_summary <- reactive({
    req(app_data$analysis[["一分差六局後狀態摘要"]])
    app_data$analysis[["一分差六局後狀態摘要"]]
  })

  venue_label <- function(venue) {
    ifelse(venue == "home", "主場", "客場")
  }

  percent_label <- function(value) {
    paste0(sprintf("%.1f", value * 100), "%")
  }

  number_label <- function(value) {
    sprintf("%.3f", value)
  }

  metric_value <- function(data, metric) {
    data$value[data$metric == metric]
  }

  output$home_win_rate <- renderText({
    data <- overall_summary()
    percent_label(data$win_rate[data$venue == "home"])
  })

  output$away_win_rate <- renderText({
    data <- overall_summary()
    percent_label(data$win_rate[data$venue == "away"])
  })

  output$home_run_gap <- renderText({
    data <- overall_summary()
    gap <- data$avg_runs_scored[data$venue == "home"] - data$avg_runs_scored[data$venue == "away"]
    number_label(gap)
  })

  output$home_away_win_rate_plot <- renderPlot({
    data <- overall_summary()
    values <- data$win_rate[match(c("home", "away"), data$venue)]
    names(values) <- c("主場", "客場")
    barplot(
      values * 100,
      ylim = c(0, max(60, max(values, na.rm = TRUE) * 115)),
      col = c("#2f80b7", "#7b8794"),
      border = NA,
      ylab = "勝率 (%)",
      main = ""
    )
    text(seq_along(values) * 1.2 - 0.5, values * 100 + 2, labels = percent_label(values), cex = 0.9)
    abline(h = 50, col = "#9fb3c8", lty = 2)
  })

  output$home_away_run_diff_plot <- renderPlot({
    data <- overall_summary()
    values <- data$avg_run_diff[match(c("home", "away"), data$venue)]
    names(values) <- c("主場", "客場")
    colors <- ifelse(values >= 0, "#2f80b7", "#b23b3b")
    barplot(
      values,
      ylim = range(c(values, 0), na.rm = TRUE) * 1.4,
      col = colors,
      border = NA,
      ylab = "平均得失分差",
      main = ""
    )
    abline(h = 0, col = "#9fb3c8")
    text(seq_along(values) * 1.2 - 0.5, values + ifelse(values >= 0, 0.025, -0.025), labels = sprintf("%.3f", values), cex = 0.9)
  })

  output$home_away_summary_table <- renderTable({
    data <- overall_summary()
    data.frame(
      場地 = venue_label(data$venue),
      場數 = data$games,
      勝場 = data$wins,
      敗場 = data$losses,
      勝率 = percent_label(data$win_rate),
      平均得分 = sprintf("%.3f", data$avg_runs_scored),
      平均失分 = sprintf("%.3f", data$avg_runs_allowed),
      平均得失分差 = sprintf("%.3f", data$avg_run_diff),
      check.names = FALSE
    )
  }, striped = TRUE, bordered = TRUE, spacing = "s")

  output$one_run_home_win_rate <- renderText({
    data <- close_game_summary()
    percent_label(data$home_win_rate[data$margin_bucket == "1_run"])
  })

  output$one_run_away_win_rate <- renderText({
    data <- close_game_summary()
    percent_label(data$away_win_rate[data$margin_bucket == "1_run"])
  })

  output$home_high_score_share <- renderText({
    data <- score_quantile_summary()
    percent_label(data$high_score_9_plus_share[data$venue == "home"])
  })

  output$away_high_score_share <- renderText({
    data <- score_quantile_summary()
    percent_label(data$high_score_9_plus_share[data$venue == "away"])
  })

  output$one_run_win_rate_gap_note <- renderText({
    data <- close_game_summary()
    home_rate <- data$home_win_rate[data$margin_bucket == "1_run"]
    away_rate <- data$away_win_rate[data$margin_bucket == "1_run"]
    gap <- home_rate - away_rate
    paste0(
      "1 分差比賽中，主場勝率為 ",
      percent_label(home_rate),
      "，客場勝率為 ",
      percent_label(away_rate),
      "，主場高出 ",
      sprintf("%.1f", gap * 100),
      " 個百分點。這支持主場在 close game 中較容易把比賽收下。"
    )
  })

  output$high_score_gap_note <- renderText({
    data <- score_quantile_summary()
    home_share <- data$high_score_9_plus_share[data$venue == "home"]
    away_share <- data$high_score_9_plus_share[data$venue == "away"]
    gap <- away_share - home_share
    paste0(
      "得分分布中，主場 9+ 分場次比例為 ",
      percent_label(home_share),
      "，客場為 ",
      percent_label(away_share),
      "，客場高出 ",
      sprintf("%.1f", gap * 100),
      " 個百分點。這可以解釋為什麼客場平均得分略高。"
    )
  })

  output$close_game_win_rate_plot <- renderPlot({
    data <- close_game_summary()
    data <- data[data$margin_bucket %in% c("1_run", "2_3_runs"), ]
    data <- data[order(match(data$margin_bucket, c("1_run", "2_3_runs"))), ]
    values <- rbind(
      "主場勝率" = data$home_win_rate * 100,
      "客場勝率" = data$away_win_rate * 100
    )
    colnames(values) <- c("1 分差", "2-3 分差")
    barplot(
      values,
      beside = TRUE,
      col = c("#2f80b7", "#7b8794"),
      border = NA,
      ylim = c(0, max(60, max(values, na.rm = TRUE) * 1.18)),
      ylab = "勝率 (%)",
      main = "",
      legend.text = row.names(values),
      args.legend = list(x = "topright", bty = "n")
    )
    abline(h = 50, col = "#9fb3c8", lty = 2)
  })

  output$score_distribution_plot <- renderPlot({
    data <- score_distribution_summary()
    bucket_order <- c("0_2_runs", "3_5_runs", "6_8_runs", "9_plus_runs")
    bucket_labels <- c("0-2 分", "3-5 分", "6-8 分", "9+ 分")
    values <- matrix(
      0,
      nrow = 2,
      ncol = length(bucket_order),
      dimnames = list(c("主場", "客場"), bucket_labels)
    )
    for (venue in c("home", "away")) {
      venue_rows <- data[data$venue == venue, ]
      row_name <- ifelse(venue == "home", "主場", "客場")
      values[row_name, ] <- venue_rows$share_of_venue_games[match(bucket_order, venue_rows$score_bucket)] * 100
    }
    barplot(
      values,
      beside = TRUE,
      col = c("#2f80b7", "#7b8794"),
      border = NA,
      ylim = c(0, max(values, na.rm = TRUE) * 1.2),
      ylab = "場次比例 (%)",
      main = "",
      legend.text = row.names(values),
      args.legend = list(x = "topright", bty = "n")
    )
  })

  output$home_no_bottom_ninth_share <- renderText({
    data <- ninth_inning_context_summary()
    percent_label(metric_value(data, "home_no_bottom_ninth_proxy_share"))
  })

  output$home_recorded_ninth_avg <- renderText({
    data <- ninth_inning_context_summary()
    number_label(metric_value(data, "home_recorded_ninth_avg_runs"))
  })

  output$home_batted_ninth_avg <- renderText({
    data <- ninth_inning_context_summary()
    number_label(metric_value(data, "home_ninth_avg_runs_when_batted_proxy"))
  })

  output$ninth_inning_context_note <- renderText({
    data <- ninth_inning_context_summary()
    games <- metric_value(data, "home_no_bottom_ninth_proxy_games")
    share <- metric_value(data, "home_no_bottom_ninth_proxy_share")
    recorded_gap <- metric_value(data, "home_recorded_ninth_gap_vs_away")
    adjusted_gap <- metric_value(data, "home_adjusted_ninth_gap_vs_away")
    paste0(
      "在資料中，主場領先且可視為未打 9 局下的比賽有 ",
      sprintf("%.0f", games),
      " 場，占全部比賽 ",
      percent_label(share),
      "。若直接把這些第 9 局下視為 0 分，主場第 9 局平均比客場少 ",
      sprintf("%.3f", abs(recorded_gap)),
      " 分；排除這些未進攻情境後，差距縮小為 ",
      sprintf("%.3f", abs(adjusted_gap)),
      " 分。"
    )
  })

  output$ninth_inning_context_plot <- renderPlot({
    data <- ninth_inning_context_summary()
    values <- c(
      metric_value(data, "away_ninth_avg_runs"),
      metric_value(data, "home_recorded_ninth_avg_runs"),
      metric_value(data, "home_ninth_avg_runs_when_batted_proxy")
    )
    names(values) <- c("客場第 9 局", "主場第 9 局紀錄", "主場實際進攻 proxy")
    barplot(
      values,
      ylim = c(0, max(values, na.rm = TRUE) * 1.25),
      col = c("#7b8794", "#b23b3b", "#2f80b7"),
      border = NA,
      ylab = "平均得分",
      main = ""
    )
    text(seq_along(values) * 1.2 - 0.5, values + 0.03, labels = sprintf("%.3f", values), cex = 0.85)
  })

  output$one_run_game_count <- renderText({
    data <- one_run_state_after_six_summary()
    sprintf("%.0f", sum(data$games, na.rm = TRUE))
  })

  output$home_win_late_run_diff <- renderText({
    data <- one_run_phase_summary()
    value <- data$avg_home_run_diff[data$winner_side == "home" & data$phase == "7_9_innings"]
    sprintf("%+.3f", value)
  })

  output$tied_after_six_home_win_rate <- renderText({
    data <- one_run_state_after_six_summary()
    percent_label(data$home_win_rate[data$state_after_6 == "tied"])
  })

  output$one_run_late_phase_note <- renderText({
    data <- one_run_phase_summary()
    home_late_diff <- data$avg_home_run_diff[data$winner_side == "home" & data$phase == "7_9_innings"]
    away_late_diff <- data$avg_home_run_diff[data$winner_side == "away" & data$phase == "7_9_innings"]
    paste0(
      "在 1 分差比賽中，主場勝場的 7-9 局平均得失分差為 ",
      sprintf("%+.3f", home_late_diff),
      "；客場勝場中，主場在 7-9 局平均得失分差為 ",
      sprintf("%+.3f", away_late_diff),
      "。這表示後段局數確實會把主場勝場與客場勝場拉開。"
    )
  })

  output$one_run_state_after_six_note <- renderText({
    data <- one_run_state_after_six_summary()
    tied <- data[data$state_after_6 == "tied", ]
    leading <- data[data$state_after_6 == "home_leading", ]
    trailing <- data[data$state_after_6 == "home_trailing", ]
    paste0(
      "若第 6 局後平手，主場最後勝率為 ",
      percent_label(tied$home_win_rate),
      "；若主場領先，最後勝率為 ",
      percent_label(leading$home_win_rate),
      "；若主場落後，仍有 ",
      percent_label(trailing$home_win_rate),
      " 的比賽能逆轉或追上後勝出。這讓「關鍵局面」可以被具體化為第 6 局後的比分狀態與後段局數表現。"
    )
  })

  output$one_run_phase_diff_plot <- renderPlot({
    data <- one_run_phase_summary()
    phase_order <- c("1_3_innings", "4_6_innings", "7_9_innings")
    phase_labels <- c("1-3 局", "4-6 局", "7-9 局")
    values <- rbind(
      "主場勝場" = data$avg_home_run_diff[data$winner_side == "home"][match(phase_order, data$phase[data$winner_side == "home"])],
      "客場勝場" = data$avg_home_run_diff[data$winner_side == "away"][match(phase_order, data$phase[data$winner_side == "away"])]
    )
    colnames(values) <- phase_labels
    barplot(
      values,
      beside = TRUE,
      col = c("#2f80b7", "#7b8794"),
      border = NA,
      ylim = range(c(values, 0), na.rm = TRUE) * 1.4,
      ylab = "主場得分 - 客場得分",
      main = "",
      legend.text = row.names(values),
      args.legend = list(x = "topright", bty = "n")
    )
    abline(h = 0, col = "#9fb3c8")
  })

  output$one_run_state_after_six_plot <- renderPlot({
    data <- one_run_state_after_six_summary()
    state_order <- c("home_leading", "tied", "home_trailing")
    state_labels <- c("主場領先", "平手", "主場落後")
    values <- data$home_win_rate[match(state_order, data$state_after_6)] * 100
    names(values) <- state_labels
    barplot(
      values,
      ylim = c(0, max(100, max(values, na.rm = TRUE) * 1.12)),
      col = c("#2f80b7", "#4f7f71", "#b23b3b"),
      border = NA,
      ylab = "最終主場勝率 (%)",
      main = ""
    )
    text(seq_along(values) * 1.2 - 0.5, values + 4, labels = paste0(sprintf("%.1f", values), "%"), cex = 0.85)
    abline(h = 50, col = "#9fb3c8", lty = 2)
  })
}
