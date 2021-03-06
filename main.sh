#!/bin/bash
# Do all the admin work around stonking

set -e

# setup dirs
mkdir -p graphs
mkdir -p data

base_url="https://cloud.iexapis.com/v1/stock"

# required for self and cruncher
python3 locket.py get_tickers > tickers.txt

# load secrets
source secrets.sh

echo "Retrieving stock data"
while read -r ticker; do
  curl -X GET "$base_url/$ticker/chart/3m?format=csv&token=$IEX_TOKEN" > "data/${ticker}_data.csv"
done < tickers.txt

echo "Crunching data"
R --no-save < crunch.R

echo "Storing calculated accuracies"
python3 locket.py store_acc

echo "Getting historical accuracies"
python3 locket.py get_acc_stats > data/accuracy_stats.csv

echo "Crunching historical accuracies"
R --no-save < accstats.R

echo "Deploying artifacts"
mv graphs/accuracies.jpg "$PUBLIC_DIR"/
mv graphs/*.jpg "$PUBLIC_DIR"/graphs/

echo "Cleaning up"
rm tickers.txt
rm -r data/
rmdir graphs

echo "Done!"
