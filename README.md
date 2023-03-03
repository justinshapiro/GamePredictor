# GamePredictor

## About

GamePredictor is a Swift script that pulls stat data from ESPN webpages and uses that data to try to predict the outcome of any given sports matchup. The script is written to support two types of prdedictions: **Straight** and **Inverted Round Robin**. 

- **Straight** predictions are simply highest probability predictions for a single game. These should be used to place a single bet with a certain number of units.
- **Inverted Round Robin** is a low-wager/high-payout parlay strategy that takes _n_ games and produces _m_ betslips that each have different sides of the spread or total selected. It's "inverted" because a regular round robin simply removes certain games from each betslip, but in this version of a round robin all _n_ games appear in each betslip but the spread or totals will be flipped for certain games in each betslip.

Currently, GamePredictor only supports spread predictions on Men's College Basketball (NCAAB), Women's College BasketBall (NCAAW), and NBA games, but given ESPN's fairly consistent webpage format across all sports, it can easily be expanded to any sport and to totals, player props, and futures as well.

## How it works 

GamePredictor will pull data from ESPN on each team in the league, this data includes record, ranking, previous games, and player stats. Right now the record, ranking and previous game data is pulled only for the current season, but each player's stats is pulled for their entire carrer. The initial pull of this data takes several days, so the data is saved in JSON files that the script will read from during subsequent runs. The script will look at each team JSON and determine if it is out of date, and pull only the data needed to make it up to date. 

Once all team data is in memory, the script will produce a list of **Betting Matchups** for use in predicting future games. Betting Matchups are simply a list of all matchups in the current season that had a line and could have been wagered on. The script will then use the Betting Matchups to create a list of **Categories**. A **Category** is a specific game scenario. An example of a category would be a team with a national ranking beating a team without a national ranking in a non-conference, non-neutral venue scenario. Each Category is assigned a _rating_ which is the percentage of games this season that fell into that Category. Categories are also assigned a _weight_ which right now corresponds to the rating but in the future can be tuned/trained to further improve prediction accuracy. 

So to predict the outcome of a current game, the script will find the categories that match each team in a given upcoming game, take the average of the ratings of all matched categories, and the team with the higher average rating is the team that is predicted to win the game.
