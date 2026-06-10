read_csv_utf8 <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
}

read_named_csvs <- function(paths) {
  available_paths <- paths[file.exists(paths)]
  lapply(available_paths, read_csv_utf8)
}

load_cleaned_data <- function() {
  read_named_csvs(c(
    "球隊比賽標籤" = "data/cleaned/team_game_model_labeled.csv",
    "勝負模型資料" = "data/cleaned/model_dataset_win.csv",
    "比賽清理資料" = "data/cleaned/cpbl_games_cleaned.csv",
    "球隊比賽特徵" = "data/cleaned/team_game_features.csv",
    "主客場摘要" = "data/cleaned/team_home_away_summary.csv"
  ))
}

load_prediction_data <- function() {
  read_named_csvs(c(
    "半局結果勝率橋接" = "data/prediction/stage1_result_state_stage2_win_bridge_output.csv",
    "打者類型 Profile" = "data/prediction/batter_type_profile.csv",
    "投手類型 Profile" = "data/prediction/pitcher_type_profile.csv"
  ))
}

load_analysis_data <- function() {
  read_named_csvs(c(
    "主客場整體摘要" = "data/analysis/home_away_overall_summary.csv",
    "主客場各隊摘要" = "data/analysis/home_away_team_summary.csv",
    "主場優勢摘要" = "data/analysis/home_field_advantage_summary.csv",
    "勝場分差摘要" = "data/analysis/home_away_win_margin_summary.csv",
    "小分差勝率摘要" = "data/analysis/home_away_close_game_summary.csv",
    "得分分布摘要" = "data/analysis/home_away_score_distribution_summary.csv",
    "得分分位數摘要" = "data/analysis/home_away_score_quantile_summary.csv",
    "逐局得分摘要" = "data/analysis/home_away_inning_score_summary.csv",
    "第九局進攻機會摘要" = "data/analysis/home_away_ninth_inning_context_summary.csv",
    "一分差階段摘要" = "data/analysis/home_away_close_one_run_phase_summary.csv",
    "一分差六局後狀態摘要" = "data/analysis/home_away_close_one_run_state_after_six_summary.csv"
  ))
}

load_app_data <- function() {
  list(
    cleaned = load_cleaned_data(),
    analysis = load_analysis_data(),
    prediction = load_prediction_data()
  )
}

summarize_dataset <- function(data) {
  data.frame(
    item = c("資料列數", "欄位數", "數值欄位", "文字欄位"),
    value = c(
      nrow(data),
      ncol(data),
      sum(vapply(data, is.numeric, logical(1))),
      sum(vapply(data, is.character, logical(1)))
    ),
    stringsAsFactors = FALSE
  )
}

first_existing_column <- function(data, candidates) {
  matches <- candidates[candidates %in% names(data)]
  if (length(matches) == 0) {
    return(NULL)
  }
  matches[[1]]
}
