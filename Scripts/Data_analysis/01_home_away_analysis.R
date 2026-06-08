input_candidates <- c(
  "data/cpbl_games_cleaned.csv",
  "data/cleaned/cpbl_games_cleaned.csv"
)
input_path <- input_candidates[file.exists(input_candidates)][1]

if (is.na(input_path)) {
  stop("Missing input data. Expected one of: ", paste(input_candidates, collapse = ", "))
}

output_dir <- "data/analysis"
figure_dir <- "docs/figures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

games <- read.csv(input_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")

required_columns <- c(
  "awayTeam",
  "homeTeam",
  "away_total_score",
  "home_total_score",
  "home_win"
)
missing_columns <- setdiff(required_columns, names(games))

if (length(missing_columns) > 0) {
  stop("Missing required columns: ", paste(missing_columns, collapse = ", "))
}

games$away_total_score <- as.numeric(games$away_total_score)
games$home_total_score <- as.numeric(games$home_total_score)
games$home_win <- as.integer(games$home_win)
games$away_win <- 1L - games$home_win

home_records <- data.frame(
  team = games$homeTeam,
  venue = "home",
  runs_scored = games$home_total_score,
  runs_allowed = games$away_total_score,
  win = games$home_win,
  stringsAsFactors = FALSE
)

away_records <- data.frame(
  team = games$awayTeam,
  venue = "away",
  runs_scored = games$away_total_score,
  runs_allowed = games$home_total_score,
  win = games$away_win,
  stringsAsFactors = FALSE
)

team_game_records <- rbind(home_records, away_records)
team_game_records$run_diff <- team_game_records$runs_scored - team_game_records$runs_allowed
team_game_records$score_bucket <- cut(
  team_game_records$runs_scored,
  breaks = c(-Inf, 2, 5, 8, Inf),
  labels = c("0_2_runs", "3_5_runs", "6_8_runs", "9_plus_runs"),
  right = TRUE
)

summarize_records <- function(data) {
  data.frame(
    games = nrow(data),
    wins = sum(data$win, na.rm = TRUE),
    losses = sum(1L - data$win, na.rm = TRUE),
    win_rate = mean(data$win, na.rm = TRUE),
    avg_runs_scored = mean(data$runs_scored, na.rm = TRUE),
    avg_runs_allowed = mean(data$runs_allowed, na.rm = TRUE),
    avg_run_diff = mean(data$run_diff, na.rm = TRUE),
    total_runs_scored = sum(data$runs_scored, na.rm = TRUE),
    total_runs_allowed = sum(data$runs_allowed, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

overall_home_away_summary <- do.call(
  rbind,
  lapply(split(team_game_records, team_game_records$venue), summarize_records)
)
overall_home_away_summary$venue <- row.names(overall_home_away_summary)
row.names(overall_home_away_summary) <- NULL
overall_home_away_summary <- overall_home_away_summary[
  ,
  c(
    "venue",
    "games",
    "wins",
    "losses",
    "win_rate",
    "avg_runs_scored",
    "avg_runs_allowed",
    "avg_run_diff",
    "total_runs_scored",
    "total_runs_allowed"
  )
]

team_home_away_summary <- do.call(
  rbind,
  lapply(split(team_game_records, list(team_game_records$team, team_game_records$venue), drop = TRUE), function(data) {
    summary <- summarize_records(data)
    summary$team <- data$team[1]
    summary$venue <- data$venue[1]
    summary
  })
)
row.names(team_home_away_summary) <- NULL
team_home_away_summary <- team_home_away_summary[
  order(team_home_away_summary$team, team_home_away_summary$venue),
  c(
    "team",
    "venue",
    "games",
    "wins",
    "losses",
    "win_rate",
    "avg_runs_scored",
    "avg_runs_allowed",
    "avg_run_diff",
    "total_runs_scored",
    "total_runs_allowed"
  )
]

home_field_advantage_summary <- data.frame(
  metric = c(
    "home_win_rate",
    "away_win_rate",
    "home_avg_runs_scored",
    "away_avg_runs_scored",
    "home_avg_run_diff",
    "away_avg_run_diff",
    "home_win_rate_advantage",
    "home_runs_scored_advantage",
    "home_run_diff_advantage"
  ),
  value = c(
    overall_home_away_summary$win_rate[overall_home_away_summary$venue == "home"],
    overall_home_away_summary$win_rate[overall_home_away_summary$venue == "away"],
    overall_home_away_summary$avg_runs_scored[overall_home_away_summary$venue == "home"],
    overall_home_away_summary$avg_runs_scored[overall_home_away_summary$venue == "away"],
    overall_home_away_summary$avg_run_diff[overall_home_away_summary$venue == "home"],
    overall_home_away_summary$avg_run_diff[overall_home_away_summary$venue == "away"],
    diff(overall_home_away_summary$win_rate[match(c("away", "home"), overall_home_away_summary$venue)]),
    diff(overall_home_away_summary$avg_runs_scored[match(c("away", "home"), overall_home_away_summary$venue)]),
    diff(overall_home_away_summary$avg_run_diff[match(c("away", "home"), overall_home_away_summary$venue)])
  ),
  stringsAsFactors = FALSE
)

win_margin_games <- data.frame(
  season = games$season,
  date = games$date,
  stadium = games$stadium,
  away_team = games$awayTeam,
  home_team = games$homeTeam,
  away_total_score = games$away_total_score,
  home_total_score = games$home_total_score,
  winner_side = ifelse(games$home_win == 1L, "home", "away"),
  winning_margin = abs(games$home_total_score - games$away_total_score),
  stringsAsFactors = FALSE
)
win_margin_games$margin_bucket <- ifelse(
  win_margin_games$winning_margin == 1,
  "1_run",
  ifelse(win_margin_games$winning_margin <= 3, "2_3_runs", "4_plus_runs")
)
win_margin_games$margin_bucket <- factor(
  win_margin_games$margin_bucket,
  levels = c("1_run", "2_3_runs", "4_plus_runs")
)

summarize_win_margins <- function(data) {
  data.frame(
    wins = nrow(data),
    share_of_side_wins = nrow(data) / sum(win_margin_games$winner_side == data$winner_side[1]),
    avg_winning_margin = mean(data$winning_margin, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

win_margin_summary <- do.call(
  rbind,
  lapply(
    split(win_margin_games, list(win_margin_games$winner_side, win_margin_games$margin_bucket), drop = TRUE),
    function(data) {
      summary <- summarize_win_margins(data)
      summary$winner_side <- data$winner_side[1]
      summary$margin_bucket <- as.character(data$margin_bucket[1])
      summary
    }
  )
)
row.names(win_margin_summary) <- NULL
win_margin_summary <- win_margin_summary[
  order(match(win_margin_summary$winner_side, c("home", "away")), match(win_margin_summary$margin_bucket, c("1_run", "2_3_runs", "4_plus_runs"))),
  c("winner_side", "margin_bucket", "wins", "share_of_side_wins", "avg_winning_margin")
]

close_game_summary <- do.call(
  rbind,
  lapply(
    split(
      win_margin_games[win_margin_games$margin_bucket %in% c("1_run", "2_3_runs"), ],
      droplevels(win_margin_games$margin_bucket[win_margin_games$margin_bucket %in% c("1_run", "2_3_runs")]),
      drop = TRUE
    ),
    function(data) {
      data.frame(
        margin_bucket = as.character(data$margin_bucket[1]),
        games = nrow(data),
        home_wins = sum(data$winner_side == "home", na.rm = TRUE),
        away_wins = sum(data$winner_side == "away", na.rm = TRUE),
        home_win_rate = mean(data$winner_side == "home", na.rm = TRUE),
        away_win_rate = mean(data$winner_side == "away", na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    }
  )
)
row.names(close_game_summary) <- NULL
close_game_summary <- close_game_summary[
  order(match(close_game_summary$margin_bucket, c("1_run", "2_3_runs"))),
]

score_distribution_summary <- do.call(
  rbind,
  lapply(
    split(team_game_records, list(team_game_records$venue, team_game_records$score_bucket), drop = TRUE),
    function(data) {
      data.frame(
        venue = data$venue[1],
        score_bucket = as.character(data$score_bucket[1]),
        games = nrow(data),
        share_of_venue_games = nrow(data) / sum(team_game_records$venue == data$venue[1]),
        win_rate = mean(data$win, na.rm = TRUE),
        avg_runs_scored = mean(data$runs_scored, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    }
  )
)
row.names(score_distribution_summary) <- NULL
score_distribution_summary <- score_distribution_summary[
  order(
    match(score_distribution_summary$venue, c("home", "away")),
    match(score_distribution_summary$score_bucket, c("0_2_runs", "3_5_runs", "6_8_runs", "9_plus_runs"))
  ),
  c("venue", "score_bucket", "games", "share_of_venue_games", "win_rate", "avg_runs_scored")
]

score_quantile_summary <- do.call(
  rbind,
  lapply(split(team_game_records, team_game_records$venue), function(data) {
    quantiles <- stats::quantile(data$runs_scored, probs = c(0, 0.25, 0.5, 0.75, 0.9, 1), na.rm = TRUE)
    data.frame(
      venue = data$venue[1],
      games = nrow(data),
      mean_runs = mean(data$runs_scored, na.rm = TRUE),
      sd_runs = stats::sd(data$runs_scored, na.rm = TRUE),
      min_runs = unname(quantiles[["0%"]]),
      q1_runs = unname(quantiles[["25%"]]),
      median_runs = unname(quantiles[["50%"]]),
      q3_runs = unname(quantiles[["75%"]]),
      p90_runs = unname(quantiles[["90%"]]),
      max_runs = unname(quantiles[["100%"]]),
      high_score_6_plus_share = mean(data$runs_scored >= 6, na.rm = TRUE),
      high_score_9_plus_share = mean(data$runs_scored >= 9, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
)
row.names(score_quantile_summary) <- NULL
score_quantile_summary <- score_quantile_summary[
  order(match(score_quantile_summary$venue, c("home", "away"))),
]

parse_inning_scores <- function(value) {
  as.numeric(strsplit(gsub("[^0-9,]", "", value), ",")[[1]])
}

score_at_inning <- function(scores, inning) {
  if (length(scores) < inning) {
    return(NA_real_)
  }
  scores[inning]
}

score_sum_innings <- function(scores, innings) {
  available_innings <- intersect(innings, seq_along(scores))
  sum(scores[available_innings], na.rm = TRUE)
}

away_inning_scores <- lapply(games$awayScores, parse_inning_scores)
home_inning_scores <- lapply(games$homeScores, parse_inning_scores)

inning_records <- do.call(
  rbind,
  lapply(seq_len(nrow(games)), function(index) {
    data.frame(
      game_index = index,
      venue = rep(c("home", "away"), each = 9),
      inning = rep(1:9, times = 2),
      runs = c(
        vapply(1:9, function(inning) score_at_inning(home_inning_scores[[index]], inning), numeric(1)),
        vapply(1:9, function(inning) score_at_inning(away_inning_scores[[index]], inning), numeric(1))
      ),
      stringsAsFactors = FALSE
    )
  })
)

inning_score_summary <- do.call(
  rbind,
  lapply(split(inning_records, list(inning_records$venue, inning_records$inning), drop = TRUE), function(data) {
    data.frame(
      venue = data$venue[1],
      inning = data$inning[1],
      batting_records = sum(!is.na(data$runs)),
      avg_runs = mean(data$runs, na.rm = TRUE),
      scoring_rate = mean(data$runs > 0, na.rm = TRUE),
      multi_run_rate = mean(data$runs >= 2, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
)
row.names(inning_score_summary) <- NULL
inning_score_summary <- inning_score_summary[
  order(match(inning_score_summary$venue, c("home", "away")), inning_score_summary$inning),
]

regulation_game <- lengths(home_inning_scores) == 9 & lengths(away_inning_scores) == 9
home_total_after_8 <- vapply(home_inning_scores, score_sum_innings, numeric(1), innings = 1:8)
away_total_after_9 <- vapply(away_inning_scores, score_sum_innings, numeric(1), innings = 1:9)
home_ninth_runs <- vapply(home_inning_scores, score_at_inning, numeric(1), inning = 9)
away_ninth_runs <- vapply(away_inning_scores, score_at_inning, numeric(1), inning = 9)
no_bottom_ninth_proxy <- regulation_game & games$home_win == 1L & home_total_after_8 > away_total_after_9
home_batted_ninth_proxy <- regulation_game & !no_bottom_ninth_proxy

ninth_inning_context_summary <- data.frame(
  metric = c(
    "regulation_games",
    "home_no_bottom_ninth_proxy_games",
    "home_no_bottom_ninth_proxy_share",
    "home_recorded_ninth_avg_runs",
    "away_ninth_avg_runs",
    "home_ninth_avg_runs_when_batted_proxy",
    "home_recorded_ninth_gap_vs_away",
    "home_adjusted_ninth_gap_vs_away"
  ),
  value = c(
    sum(regulation_game),
    sum(no_bottom_ninth_proxy),
    mean(no_bottom_ninth_proxy),
    mean(home_ninth_runs[regulation_game], na.rm = TRUE),
    mean(away_ninth_runs[regulation_game], na.rm = TRUE),
    mean(home_ninth_runs[home_batted_ninth_proxy], na.rm = TRUE),
    mean(home_ninth_runs[regulation_game], na.rm = TRUE) - mean(away_ninth_runs[regulation_game], na.rm = TRUE),
    mean(home_ninth_runs[home_batted_ninth_proxy], na.rm = TRUE) - mean(away_ninth_runs[regulation_game], na.rm = TRUE)
  ),
  stringsAsFactors = FALSE
)

one_run_game <- abs(games$home_total_score - games$away_total_score) == 1
phase_definitions <- list(
  early = 1:3,
  middle = 4:6,
  late = 7:9
)
phase_labels <- c(
  early = "1_3_innings",
  middle = "4_6_innings",
  late = "7_9_innings"
)

close_one_run_phase_records <- do.call(
  rbind,
  lapply(names(phase_definitions), function(phase_name) {
    innings <- phase_definitions[[phase_name]]
    data.frame(
      game_index = seq_len(nrow(games)),
      phase = phase_labels[[phase_name]],
      winner_side = ifelse(games$home_win == 1L, "home", "away"),
      home_runs = vapply(home_inning_scores, score_sum_innings, numeric(1), innings = innings),
      away_runs = vapply(away_inning_scores, score_sum_innings, numeric(1), innings = innings),
      stringsAsFactors = FALSE
    )
  })
)
close_one_run_phase_records <- close_one_run_phase_records[one_run_game[close_one_run_phase_records$game_index], ]
close_one_run_phase_records$home_run_diff <- close_one_run_phase_records$home_runs - close_one_run_phase_records$away_runs

close_one_run_phase_summary <- do.call(
  rbind,
  lapply(
    split(close_one_run_phase_records, list(close_one_run_phase_records$winner_side, close_one_run_phase_records$phase), drop = TRUE),
    function(data) {
      data.frame(
        winner_side = data$winner_side[1],
        phase = data$phase[1],
        games = nrow(data),
        avg_home_runs = mean(data$home_runs, na.rm = TRUE),
        avg_away_runs = mean(data$away_runs, na.rm = TRUE),
        avg_home_run_diff = mean(data$home_run_diff, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    }
  )
)
row.names(close_one_run_phase_summary) <- NULL
close_one_run_phase_summary <- close_one_run_phase_summary[
  order(
    match(close_one_run_phase_summary$winner_side, c("home", "away")),
    match(close_one_run_phase_summary$phase, c("1_3_innings", "4_6_innings", "7_9_innings"))
  ),
]

home_total_after_6 <- vapply(home_inning_scores, score_sum_innings, numeric(1), innings = 1:6)
away_total_after_6 <- vapply(away_inning_scores, score_sum_innings, numeric(1), innings = 1:6)
home_late_runs <- vapply(home_inning_scores, score_sum_innings, numeric(1), innings = 7:9)
away_late_runs <- vapply(away_inning_scores, score_sum_innings, numeric(1), innings = 7:9)
state_after_6 <- ifelse(
  home_total_after_6 > away_total_after_6,
  "home_leading",
  ifelse(home_total_after_6 < away_total_after_6, "home_trailing", "tied")
)

close_one_run_state_after_six_summary <- do.call(
  rbind,
  lapply(split(seq_len(nrow(games))[one_run_game], state_after_6[one_run_game], drop = TRUE), function(indexes) {
    data.frame(
      state_after_6 = state_after_6[indexes][1],
      games = length(indexes),
      home_wins = sum(games$home_win[indexes] == 1L, na.rm = TRUE),
      away_wins = sum(games$home_win[indexes] == 0L, na.rm = TRUE),
      home_win_rate = mean(games$home_win[indexes] == 1L, na.rm = TRUE),
      avg_home_late_runs = mean(home_late_runs[indexes], na.rm = TRUE),
      avg_away_late_runs = mean(away_late_runs[indexes], na.rm = TRUE),
      avg_late_home_run_diff = mean(home_late_runs[indexes] - away_late_runs[indexes], na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
)
row.names(close_one_run_state_after_six_summary) <- NULL
close_one_run_state_after_six_summary <- close_one_run_state_after_six_summary[
  order(match(close_one_run_state_after_six_summary$state_after_6, c("home_leading", "tied", "home_trailing"))),
]

write.csv(
  overall_home_away_summary,
  file.path(output_dir, "home_away_overall_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  team_home_away_summary,
  file.path(output_dir, "home_away_team_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  home_field_advantage_summary,
  file.path(output_dir, "home_field_advantage_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  win_margin_games,
  file.path(output_dir, "home_away_win_margin_games.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  win_margin_summary,
  file.path(output_dir, "home_away_win_margin_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  close_game_summary,
  file.path(output_dir, "home_away_close_game_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  score_distribution_summary,
  file.path(output_dir, "home_away_score_distribution_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  score_quantile_summary,
  file.path(output_dir, "home_away_score_quantile_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  inning_score_summary,
  file.path(output_dir, "home_away_inning_score_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  ninth_inning_context_summary,
  file.path(output_dir, "home_away_ninth_inning_context_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  close_one_run_phase_summary,
  file.path(output_dir, "home_away_close_one_run_phase_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  close_one_run_state_after_six_summary,
  file.path(output_dir, "home_away_close_one_run_state_after_six_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

ordered_overall_summary <- overall_home_away_summary[
  match(c("home", "away"), overall_home_away_summary$venue),
]
venue_labels <- c("主場", "客場")

render_bar_chart <- function(path, values, labels, colors, ylab, title, value_labels, ylim = NULL) {
  png(path, width = 960, height = 620, res = 140)
  old_par <- par(no.readonly = TRUE)
  on.exit({
    par(old_par)
    dev.off()
  })

  par(mar = c(5, 5, 4, 2), family = "sans")
  bars <- barplot(
    values,
    names.arg = labels,
    col = colors,
    border = NA,
    ylim = ylim,
    ylab = ylab,
    main = title,
    cex.main = 1.2,
    cex.names = 1,
    cex.lab = 1
  )
  grid(nx = NA, ny = NULL, col = "#d9e2ec", lty = 1)
  barplot(
    values,
    names.arg = labels,
    col = colors,
    border = NA,
    ylim = ylim,
    ylab = ylab,
    main = title,
    add = TRUE
  )
  text(
    bars,
    values + ifelse(values >= 0, max(abs(values)) * 0.06, -max(abs(values)) * 0.06),
    labels = value_labels,
    cex = 0.95,
    col = "#102a43"
  )
}

win_rate_values <- ordered_overall_summary$win_rate * 100
render_bar_chart(
  file.path(figure_dir, "home_away_win_rate.png"),
  values = win_rate_values,
  labels = venue_labels,
  colors = c("#2f80b7", "#7b8794"),
  ylab = "勝率 (%)",
  title = "主客場勝率",
  value_labels = paste0(sprintf("%.1f", win_rate_values), "%"),
  ylim = c(0, max(60, max(win_rate_values, na.rm = TRUE) * 1.15))
)

run_diff_values <- ordered_overall_summary$avg_run_diff
render_bar_chart(
  file.path(figure_dir, "home_away_run_diff.png"),
  values = run_diff_values,
  labels = venue_labels,
  colors = ifelse(run_diff_values >= 0, "#2f80b7", "#b23b3b"),
  ylab = "平均得失分差",
  title = "主客場平均得失分差",
  value_labels = sprintf("%.3f", run_diff_values),
  ylim = range(c(run_diff_values, 0), na.rm = TRUE) * 1.5
)

margin_bucket_labels <- c("1 分差", "2-3 分差", "4+ 分差")
margin_matrix <- matrix(
  0,
  nrow = 2,
  ncol = 3,
  dimnames = list(c("主場勝場", "客場勝場"), margin_bucket_labels)
)
for (side in c("home", "away")) {
  side_rows <- win_margin_summary[win_margin_summary$winner_side == side, ]
  side_index <- ifelse(side == "home", "主場勝場", "客場勝場")
  margin_matrix[side_index, margin_bucket_labels] <- side_rows$share_of_side_wins[match(c("1_run", "2_3_runs", "4_plus_runs"), side_rows$margin_bucket)] * 100
}

png(file.path(figure_dir, "home_away_win_margin_distribution.png"), width = 1040, height = 620, res = 140)
old_par <- par(no.readonly = TRUE)
par(mar = c(5, 5, 4, 2), family = "sans")
bars <- barplot(
  margin_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(margin_matrix, na.rm = TRUE) * 1.2),
  ylab = "占該方勝場比例 (%)",
  main = "主客場勝場分差分布",
  legend.text = row.names(margin_matrix),
  args.legend = list(x = "topright", bty = "n")
)
grid(nx = NA, ny = NULL, col = "#d9e2ec", lty = 1)
barplot(
  margin_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(margin_matrix, na.rm = TRUE) * 1.2),
  ylab = "占該方勝場比例 (%)",
  main = "主客場勝場分差分布",
  add = TRUE
)
text(bars, margin_matrix + 2, labels = paste0(sprintf("%.1f", margin_matrix), "%"), cex = 0.8)
par(old_par)
dev.off()

close_rate_matrix <- rbind(
  "主場勝率" = close_game_summary$home_win_rate * 100,
  "客場勝率" = close_game_summary$away_win_rate * 100
)
colnames(close_rate_matrix) <- c("1 分差", "2-3 分差")

png(file.path(figure_dir, "home_away_close_game_win_rate.png"), width = 900, height = 620, res = 140)
old_par <- par(no.readonly = TRUE)
par(mar = c(5, 5, 4, 2), family = "sans")
bars <- barplot(
  close_rate_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(60, max(close_rate_matrix, na.rm = TRUE) * 1.18)),
  ylab = "勝率 (%)",
  main = "小分差比賽主客場勝率",
  legend.text = row.names(close_rate_matrix),
  args.legend = list(x = "topright", bty = "n")
)
grid(nx = NA, ny = NULL, col = "#d9e2ec", lty = 1)
barplot(
  close_rate_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(60, max(close_rate_matrix, na.rm = TRUE) * 1.18)),
  ylab = "勝率 (%)",
  main = "小分差比賽主客場勝率",
  add = TRUE
)
text(bars, close_rate_matrix + 2, labels = paste0(sprintf("%.1f", close_rate_matrix), "%"), cex = 0.8)
abline(h = 50, col = "#9fb3c8", lty = 2)
par(old_par)
dev.off()

score_bucket_labels <- c("0-2 分", "3-5 分", "6-8 分", "9+ 分")
score_distribution_matrix <- matrix(
  0,
  nrow = 2,
  ncol = 4,
  dimnames = list(c("主場", "客場"), score_bucket_labels)
)
for (venue in c("home", "away")) {
  venue_rows <- score_distribution_summary[score_distribution_summary$venue == venue, ]
  venue_index <- ifelse(venue == "home", "主場", "客場")
  score_distribution_matrix[venue_index, score_bucket_labels] <- venue_rows$share_of_venue_games[
    match(c("0_2_runs", "3_5_runs", "6_8_runs", "9_plus_runs"), venue_rows$score_bucket)
  ] * 100
}

png(file.path(figure_dir, "home_away_score_distribution.png"), width = 1040, height = 620, res = 140)
old_par <- par(no.readonly = TRUE)
par(mar = c(5, 5, 4, 2), family = "sans")
bars <- barplot(
  score_distribution_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(score_distribution_matrix, na.rm = TRUE) * 1.2),
  ylab = "占該場地進攻場次比例 (%)",
  main = "主客場得分分布",
  legend.text = row.names(score_distribution_matrix),
  args.legend = list(x = "topright", bty = "n")
)
grid(nx = NA, ny = NULL, col = "#d9e2ec", lty = 1)
barplot(
  score_distribution_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(score_distribution_matrix, na.rm = TRUE) * 1.2),
  ylab = "占該場地進攻場次比例 (%)",
  main = "主客場得分分布",
  add = TRUE
)
text(bars, score_distribution_matrix + 2, labels = paste0(sprintf("%.1f", score_distribution_matrix), "%"), cex = 0.75)
par(old_par)
dev.off()

high_score_matrix <- rbind(
  "6+ 分比例" = score_quantile_summary$high_score_6_plus_share * 100,
  "9+ 分比例" = score_quantile_summary$high_score_9_plus_share * 100
)
colnames(high_score_matrix) <- ifelse(score_quantile_summary$venue == "home", "主場", "客場")

png(file.path(figure_dir, "home_away_high_score_share.png"), width = 900, height = 620, res = 140)
old_par <- par(no.readonly = TRUE)
par(mar = c(5, 5, 4, 2), family = "sans")
bars <- barplot(
  high_score_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(high_score_matrix, na.rm = TRUE) * 1.2),
  ylab = "場次比例 (%)",
  main = "主客場高得分場次比例",
  legend.text = row.names(high_score_matrix),
  args.legend = list(x = "topright", bty = "n")
)
grid(nx = NA, ny = NULL, col = "#d9e2ec", lty = 1)
barplot(
  high_score_matrix,
  beside = TRUE,
  col = c("#2f80b7", "#7b8794"),
  border = NA,
  ylim = c(0, max(high_score_matrix, na.rm = TRUE) * 1.2),
  ylab = "場次比例 (%)",
  main = "主客場高得分場次比例",
  add = TRUE
)
text(bars, high_score_matrix + 2, labels = paste0(sprintf("%.1f", high_score_matrix), "%"), cex = 0.8)
par(old_par)
dev.off()

cat("Input:", input_path, "\n")
cat("Rows:", nrow(games), "games\n")
cat("Wrote:", file.path(output_dir, "home_away_overall_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_team_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_field_advantage_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_win_margin_games.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_win_margin_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_close_game_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_score_distribution_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_score_quantile_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_inning_score_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_ninth_inning_context_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_close_one_run_phase_summary.csv"), "\n")
cat("Wrote:", file.path(output_dir, "home_away_close_one_run_state_after_six_summary.csv"), "\n")
cat("Wrote:", file.path(figure_dir, "home_away_win_rate.png"), "\n")
cat("Wrote:", file.path(figure_dir, "home_away_run_diff.png"), "\n")
cat("Wrote:", file.path(figure_dir, "home_away_win_margin_distribution.png"), "\n")
cat("Wrote:", file.path(figure_dir, "home_away_close_game_win_rate.png"), "\n")
cat("Wrote:", file.path(figure_dir, "home_away_score_distribution.png"), "\n")
cat("Wrote:", file.path(figure_dir, "home_away_high_score_share.png"), "\n")
