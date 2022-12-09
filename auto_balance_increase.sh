#!/bin/bash
function=main
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>>$HOME/auto_balance_increase/out.log 2>&1

CHAT_ID=''
BOT_TOKEN=''
WALLET_ADDRESS=''
CLUSTER=''

SOLANA_PATH="$HOME/.local/share/solana/install/active_release/bin/solana"
FILE_WITH_ADDRESSES="$HOME/auto_balance_increase/addresses.txt"
WALLET_PATH="$HOME/auto_balance_increase/keypair.json"
REQUIREMENTS="$HOME/auto_balance_increase/requirements.info"

MIN_BALANCE='0.50'
TRANSFER_AMOUNT='0.50'

# logging
log() {
    echo "$(date) : $1" >&1
}

# procedure for extracting important variables
get_requirements() {
    while IFS= read -r _line
    do
        local arr=( $_line )
        local name_column=${arr[0]}
        local values=${arr[1]}

        if [ "$name_column" == "CHAT_ID" ]; then
            CHAT_ID=$values
            log "Extracting a variable CHAT_ID $CHAT_ID"
        fi
        if [ "$name_column" == "BOT_TOKEN" ]; then
            BOT_TOKEN=$values
            log "Extracting a variable BOT_TOKEN $BOT_TOKEN"
        fi
        if [ "$name_column" == "WALLET_ADDRESS" ]; then
            WALLET_ADDRESS=$values
            log "Extracting a variable WALLET_ADDRESS $WALLET_ADDRESS"
        fi
        if [ "$name_column" == "CLUSTER" ]; then
            CLUSTER=$values
            log "Extracting a variable CLUSTER $CLUSTER"
        fi
    done < $REQUIREMENTS

    if [ -z "$CHAT_ID" ]; then
        log "Failed to extract variable CHAT_ID from file requirements.info"
        exit 0
    fi
    
    if [ -z "$BOT_TOKEN" ]; then
        log "Failed to extract variable BOT_TOKEN from file requirements.info"
        exit 0
    fi

    if [ -z "$WALLET_ADDRESS" ]; then
        log "Failed to extract variable WALLET_ADDRESS from file requirements.info"
        exit 0
    fi
    
    if [ -z "$CLUSTER" ]; then
        log "Failed to extract variable CLUSTER from file requirements.info"
        exit 0
    fi
}

# balance request (key address argument)
get_balance () {
    local __balance=$(printf "%.2f" $($SOLANA_PATH balance $1 -u$CLUSTER | awk '{print $1}'))
    echo $__balance
}

# transfer (recipient's key address argument)
transfer() {
    log "Replenishment of the balance $1 on $TRANSFER_AMOUNT SOL."
    $SOLANA_PATH transfer --allow-unfunded-recipient --keypair $WALLET_PATH -u$CLUSTER $1 $TRANSFER_AMOUNT &>/dev/null
}

# sending a message to a telegram bot
send_msg_transfer() {
    local _public_key=$1
    local _balance_wallet=$2
    local _msg="The transfer was made to ${_public_key:0:7},\n the balance on the main wallet $_balance_wallet SOL."
    curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID"'","text":"'"$_msg"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" &>/dev/null
}

# sending a message to a telegram bot
send_msg_empty_wallet() {
    local __balance_wallet=$1
    local __msg="ATTANTION!!!\nThe balance of the main wallet is $__balance_wallet SOL.\n Top up his balance, otherwise the check will not be performed."
    curl --header 'Content-Type: application/json' --request 'POST' --data '{"chat_id":"'"$CHAT_ID"'","text":"'"$__msg"'"}' "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" &>/dev/null
}

# the main function of auto-payments
main() {
    get_requirements

    while IFS= read -r line
    do
        local balance_wallet=$(get_balance $WALLET_ADDRESS)
        log "Balance main wallet - $balance_wallet SOL."

        if [[ $(echo "${balance_wallet} < ${MIN_BALANCE}" | bc) -eq 1 ]]; then
            log "Script completion (missing sol)."
            send_msg_empty_wallet $balance_wallet
            exit 0
        fi

        local public_key="$line"
        local balance=$(get_balance $public_key)

        log "Balance at the address ($public_key) is $balance SOL."

        if [[ $(echo "${balance} < ${MIN_BALANCE}" | bc) -eq 1 ]]; then
            transfer $public_key

            sleep 1

            balance=$(get_balance $public_key)
            balance_wallet=$(get_balance $WALLET_ADDRESS)

            send_msg_transfer $public_key $balance_wallet
        fi
    done < $FILE_WITH_ADDRESSES
}

$function