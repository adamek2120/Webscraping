# Webscraping

During my master's degree, I used SPSS for performing any statistical analysis however, early in my Ph.D program I was introduced to R and have not looked back since! R is more then just a program to run statistics ranging from basic descriptives to latent class modeling or neural networks. It's superior power also makes R the ideal langauge for running simulations with large iterations. However, before running any analyzes or simulations you need data. You can input a data file or... you can scrape data straight from a website. 

## Introduction

I love baseball so, of course, when I began teaching myself R I would relay on using baseball data over the common built-in R datasets used most learning resources (e.g., iris, mtcars, NYCflights). The Lahman and baseballr package in R are great tools that contain historical baseball data (Lahman) and functions with embedded APIs to extract data from statcast and fangraphs (baseballr), however you're restricted to the limits of the package. Also, scraping data from a website can better ensure that each time you run the code the data being pulled in is always up to date.    

When I first started learning R I was also taking statistic courses during my Ph.D at the University of Illinos at Urbana-Champaign. One of the first courses I took focused on probability theory and Bayesian statistics. About this same time, sports betting was becoming legal in Illinois and a popular betting type on MLB games was betting whether there would be a run scored in the first inning. During this time, the market was VERY favorable giving near even money (-110) for yes/no. Funny enough, I read somewhere that this lasted barely a year until Vegas and all sport bookies caught on and adjusted the 1st inning moneyline so the return is less. Either way, I started creating a model to predict whether a team would score a run in the first inning. The complete model includes data relating to the starting pitcher as well however, for the purpose of this article, I'll just focus on the overall team performance in the first inning for simplicity. Specifically, we'll scrape the percentage of the time a team scores in the first inning ("yes-run-first-inning-pct") and the percentage of the time a team allows a run to be scored in the first inning ("opponent-yes-run-first-inning-pct"). Ultimately, you want data specific to the starting pitcher and lineup for a given team but this provides a good starting point! In fact, when we're done, you can use the data we scraped here to predict the three different types of 1st inning bets: Team A wins (Team A scores and Team B does not), Team B wins (Team B scores and Team A does not), and Tie (for this example we'll simply define tie as neither Team A or Team B scores). This could be done with the following probability formulas (not covered in this article):

P(A) = Probability that Team A scores in the first inning
P(B) = Probability that Team B scores in the first inning
P(A and not B) = P(A) - P(A and B) = Probability that Team A scores and not Team B in the first inning
P(B and not A') = P(B) - P(A and B) = Probability that Team B scores and not Team A in the first inning
P(not A and not B) = 1 - P(A or B) = Probability that neither team scores in the first inning

## Webscraping Teamrankings.com

Before we get started, we need to make sure we have the necessary packages installed. We will be using "rvest", "stringr", "dplyr", and "purrr". If you do not have these packages installed, you can install them by running the following command:

```
install.packages(c("rvest", "stringr", "dplyr", "purrr"))
```

Once we have the packages installed, we can start by loading them into our R session:

```
library(rvest)
library(stringr)
library(dplyr) 
library(purrr) 
```

We will use the website "https://www.teamrankings.com" to scrape data for Major League Baseball (MLB) teams. First, we will create an object with the website address using the following code:

```
tr_url <- "https://www.teamrankings.com/mlb/team-stats/"
tr <- read_html(tr_url)
```

This creates an object called "tr" that contains the HTML content of the MLB team stats page.

We can now extract the links from the page using the "html_nodes" and "html_attr" functions from rvest. In this case, we are interested in the links to the various MLB team stats pages. We can extract these links using the following code:

```
tr_links <- tr %>% 
  html_nodes("a") %>% 
  html_attr("href")
head(tr_links,10)
```

This creates a character vector called "tr_links" that contains all of the links on the MLB team stats page.

We only want to extract the links for the MLB team stats pages, so we need to filter out the other links. We can do this using the str_detect() function from stringr. We will also remove the links that contain "/mlb/stats/" using the negation operator !. We can extract the MLB team stats page links using the following code:

```
mlb_links <- tr_links[str_detect(tr_links,"mlb/stat")]
mlb_links <- mlb_links[!str_detect(mlb_links, "/mlb/stats/")]
```

This creates a character vector called "mlb_links" that contains the links to the various MLB team stats pages.

We will now create a dataframe with the mlb_links using the tibble() function from the dplyr package:

```
df <- tibble(stat_links = mlb_links)
```

This creates a dataframe called "df" that contains a column of links to the various MLB team stats pages.

We are interested in the first inning scoring percentages, so we need to filter out the other stats. We will use the str_detect() function again to create a new variable 'is_per_first' that indicates whether the link contains the relevant statistic. We will filter the dataframe df to only include links that contain the the statistic for first inning scoring percentage, in this case "yes-run-first-inning-pct".

```
df <- df %>% 
  mutate(is_per_first = str_detect(stat_links, "yes-run-first-inning-pct")) %>% 
  filter(is_per_first == TRUE)
```

We will now repeat the same process for the opponent's yes/no run percentage.

```
df1 <- df %>% 
  mutate(is_opp = str_detect(stat_links, "opponent-yes-run-first-inning-pct")) %>% 
  filter(is_opp == TRUE)
```

Next, we will fix the links to include the website address "https://www.teamrankings.com". We will store the fixed links in the variables df and df1 using the paste0() function.

```
df <- df %>% 
  mutate(url = paste0('https://www.teamrankings.com', stat_links))
df1 <- df1 %>% 
  mutate(url = paste0('https://www.teamrankings.com', stat_links))
```

We will now define a function called get_page() that downloads a webpage given a URL. The function also includes a delay between requests using the Sys.sleep() function to prevent the website from blocking our requests!

```
get_page <- function(url){
  page <- read_html(url)
  Sys.sleep(sample(seq(.25,2.5,.25),1))
  page
}
```

Next, we use map from the purrr package to apply the get_page function to each URL in the url column of two data frames called df and df1. The resulting page_data and page_data1 lists will contain the downloaded pages for each URL.

```
page_data <- map(df$url, get_page)
page_data1 <- map(df1$url, get_page)
```

After downloading the pages, we use html_table from the rvest package to extract tables from the pages in the page_data and page_data1 lists. The resulting tr_data and tr_data1 lists will contain the tables from the pages.

```
tr_data <- map(page_data, html_table)
tr_data1 <- map(page_data1, html_table)
```

In the next step, we combine the tables together by binding them into a single data frame. We use the pluck() function from the purrr package to extract the first element of the tr_data list, and then use map2_df() from the purrr package to combine the table data with the corresponding URLs from the df data frame above. We then use set_names to assign column names to the resulting data frame (these are the columns from table on the teamrankings.com website). This process is repeated for tr_data1 and df1, resulting in a data frame for opponent stats and another for team stats.

```
# Teams yes/no run percentage
tr_data <- pluck(tr_data, 1) %>% 
  map2_df(df$stat_links, 
          ~as_tibble(.x) %>% 
            mutate(stat = .y)) %>% 
  set_names(c(
    'rank',
    'team',
    'current_seas',
    'last_3',     # Last 3 games
    'last_1',     # Last Game
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
```

After binding all the tables together, we then filter and select the relevant data to create two separate datasets the team stats and opponent stats. The team_data dataset only includes data for the percentage of games in which the team has scored a run in the first inning, while the opp_data dataset only includes data for the percentage of games in which the team allowed the opponent to score a run in the first inning.


The team_data dataset is created by filtering the tr_data dataset on the '/mlb/stat/yes-run-first-inning-pct' string and selecting only the columns of interest. In this example we're interested in:  'rank', 'team', 'current_seas', 'last_3', 'last_1', 'home', 'away', and 'last_seas'.

```
team_data <- tr_data %>% 
  filter(stat == '/mlb/stat/yes-run-first-inning-pct') %>% 
  select(-last_3, -last_1, -stat)
```

For the opp_data dataset we either filter by stat = '/mlb/stat/opponent-yes-run-first-inning-pct' or since tr_data1 already contains the dataset for these variables we can simply just select the same columns of interest as we did above:

```
opp_data <- tr_data1 %>% 
  select(-last_3, -last_1, -stat)
```

We're done here! 

Sometimes I like to clean up the global environment so that it isn't as messy and just contains the objects that we want. We can use the following code to remove everything except for team_data and opp_data:

```
rm(df, df1, page_data, page_data1, tr, tr_data, tr_data1, mlb_links, tr_links, get_page, tr_url)
```
