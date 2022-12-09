# Auto balance increase SOL

## Installation process
```
sudo apt-get update \
&& sudo apt-get install git -y \
&& git clone https://github.com/EvgeniiPerkin/auto_balance_increase.git \
&& cd auto_balance_increase \
&& echo "CHAT_ID           your_CHAT_ID" >> requirements.info \
&& echo "CHAT_ALARM        your_CHAT_ALARM" >> requirements.info \
&& echo "BOT_TOKEN         your_BOT_TOKEN" >> requirements.info \
&& echo "WALLET_ADDRESS    your_WALLET_ADDRESS" >> requirements.info \
&& echo "CLUSTER           your_CLUSTER" >> requirements.info \
&& echo "" >> requirements.info \
&& touch addresses.txt
```

* Next, copy your key to the $HOME/auto_balance_increase directory.
* Fill in the file $HOME/auto_balance_increase/requirements.txt
* Fill in the addresses $HOME/auto_balance_increase/addresses.txt with your data.
* And configure crontab at your discretion.

If you have any problems, you can view the log.
```
tail -f $HOME/auto_balance_increase/out.log
```