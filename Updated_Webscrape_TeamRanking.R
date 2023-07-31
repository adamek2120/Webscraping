
library(rvest)
library(stringr)
library(dplyr) # for tibble
library(purrr) # for map function

# Layout: https://www.corywaters.com/2017/10/06/scraping-nfl-data-with-r/

# Creating object with the address
tr_url <- "https://www.teamrankings.com/mlb/team-stats/"
tr <- read_html(tr_url)

# Getting links
tr_links <- tr %>% 
  html_nodes("a") %>% 
  html_attr("href")
head(tr_links,10)


mlb_links <- tr_links[str_detect(tr_links,"mlb/stat")]
head(mlb_links)


mlb_links <- mlb_links[!str_detect(mlb_links, "/mlb/stats/")]

# Puts links in dataframe
df <- tibble(stat_links = mlb_links)

# Find per first inning stats
df <- df %>% 
  mutate(is_per_first = str_detect(stat_links, "yes-run-first-inning-pct")) %>% 
  filter(is_per_first == TRUE)

df1 <- df %>% 
  mutate(is_opp = str_detect(stat_links, "opponent-yes-run-first-inning-pct")) %>% 
  filter(is_opp == TRUE)

# Fixing the links
df <- df %>% 
  mutate(url = paste0('https://www.teamrankings.com', stat_links))
df1 <- df1 %>% 
  mutate(url = paste0('https://www.teamrankings.com', stat_links))
df1 %>% 
  head() %>% 
  knitr::kable()

# Downloadinbg the web page
get_page <- function(url){
  page <- read_html(url)
  Sys.sleep(sample(seq(.25,2.5,.25),1))
  page
}

page_data <- map(df$url, get_page)
page_data1 <- map(df1$url, get_page)
tr_data <- map(page_data, html_table)
tr_data1 <- map(page_data1, html_table)
# Binding all the tables together
# This below is both opponent and the teams stats
tr_data <- pluck(tr_data, 1) %>% 
  map2_df(df$stat_links, 
          ~as_tibble(.x) %>% 
            mutate(stat = .y)) %>% 
  set_names(c(
    'rank',
    'team',
    'current_seas',
    'last_3',
    'last_1',
    'home',
    'away',
    'last_seas',
    'stat'
  ))
# Opponents yes/no run percentage
tr_data1 <- pluck(tr_data1, 1) %>% 
  map2_df(df1$stat_links, 
          ~as_tibble(.x) %>% 
            mutate(stat = .y)) %>% 
  set_names(c(
    'rank',
    'team',
    'current_seas',
    'last_3',
    'last_1',
    'home',
    'away',
    'last_seas',
    'stat'
  ))

# Create two datasets for team stat and Opp stat
team_data <- tr_data %>% 
  filter(stat == '/mlb/stat/yes-run-first-inning-pct') %>% 
  select(-last_3, -last_1, -stat)
  

opp_data <- tr_data1 %>% 
  select(-last_3, -last_1, -stat)

# Leaves on taem_data and opp_data
rm(df, df1, page_data, page_data1, tr, tr_data, tr_data1, mlb_links, tr_links, get_page, tr_url)


