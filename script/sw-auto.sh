#!/usr/bin/env bash

set -e

MACHINE_UUID="93c5a673-04e9-40cd-9233-a21de59d304f"
BOT_API="5984183633:AAGYRJlP12lqyc8rMlnKKdizguZgrKqiqPc"
CHAT_ID="1969557829"
WAIT=600

STAR_MACHINE() {
    scw instance server start "${MACHINE_UUID}"
}

SEND_NOTIFY() {
    curl -X POST \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": '"${CHAT_ID}"', "text": "Your Sacleway machine is opening now."}' \
        https://api.telegram.org/bot"${BOT_API}"/sendMessage
}

while true; do
    STATUS=$(scw instance server list | sed -n '2p' | awk '{print $4}')
    if [[ ${STATUS} == "starting" ]]; then
        echo "Your server status is ${STATUS}"
        echo "Wait for $WAIT seconds to check again ..."
        sleep $WAIT
    elif [[ ${STATUS} == "archived" ]]; then
        echo "Your server status is ${STATUS}"
        echo "Now start your machine ..."
        STAR_MACHINE
        sleep $WAIT
    else
        SEND_NOTIFY
        break
    fi
done
