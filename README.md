[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/xfVbwuLD)
# [GroupID] your project title
The goals of this project.

## Contributors
|組員|系級|學號|工作分配|
|-|-|-|-|
|何大南|資科碩二|xxxxxxxxx|團隊中的吉祥物🦒，負責增進團隊氣氛| 
|張小明|資科碩二|xxxxxxxxx|團隊的中流砥柱，一個人打十個|

## Quick start
Please provide an example command or a few commands to reproduce your analysis, such as the following R script:
```R
Rscript code/your_script.R --input data/training --output results/performance.tsv
```

## Folder organization and its related description
idea by Noble WS (2009) [A Quick Guide to Organizing Computational Biology Projects.](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1000424) PLoS Comput Biol 5(7): e1000424.

### docs
* Your presentation, 1142_DS-FP_groupID.ppt/pptx/pdf (i.e.,1142_DS-FP_group1.ppt), by **06.09**
* Any related document for the project, i.e.,
  * discussion log
  * software user guide

### data
* Input
  * Source
  * Format
  * Size

### code
* Analysis steps
* Which method or package do you use?
* How do you perform training and evaluation?
  * Cross-validation, or extra separated data
* What is a null model for comparison?

### results
* What is your performance?
* Is the improvement significant?

## References
* Packages you use
* Related publications

# CPBL Data Science

## 資料分析概要

從 2024-2025 CPBL賽季數據當中，從主客場角度觀察勝負現象會發現到，主場勝率高於客場，表示主場環境因素確實可能影響勝負。
<table>
  <tr>
    <td>
      <img src="docs/figures/home_away_win_rate.png" alt="主客場勝率" width="420">
    </td>
    <td>
      <img src="docs/figures/home_away_run_diff.png" alt="主客場平均得失分差" width="420">
    </td>
  </tr>
</table>
不過，從圖表上顯示主場平均得分並沒有高於客場，反而略低於客場。形成一個值得觀察的現象：主場優勢確實存在並且具有影響勝負的關鍵，但其中影響勝負的因素並不單純來自得分。


## 專案結構

```text
app.R
R/
  data_loader.R
  ui_analysis.R
  server_analysis.R
  prediction_app.R
www/
  styles.css
data/
  raw/
  cleaned/
  prediction/
```

## 頁面主題

### 資料分析



### 預測結果

整合互動式 CPBL state prediction prototype，使用 `data/prediction/` 內的半局 result-state 預測、勝率橋接結果、打者類型 profile 與投手類型 profile。



## 執行方式

在專案根目錄啟動 Shiny app：

```r
shiny::runApp()
```

或在終端機執行：

```bash
Rscript -e "shiny::runApp()"
```

## 資料資料夾

`data/raw/` 保留原始資料。

`data/cleaned/` 放資料分析與模型訓練後整理出的資料。

`data/prediction/` 放 Shiny 預測結果頁需要讀取的模型輸出與球員 profile。
