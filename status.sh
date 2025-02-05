#!/bin/bash

# script by @szvy on github
# completely free to use, please just have credit to me
# also make sure you read the readme on the github
# https://github.com/szvy/statuswebhook

DISCORD_WEBHOOK_URL="YOUR WEBHOOK HERE" # webhook to send status updates to
PREVIOUS_STATUS="UNKNOWN" # tracks the previous status to prevent sending multiple alerts
ROLE_ID="YOUR ROLE ID HERE" # role for pinging members

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ") # message for webhook if the site is up
JSON_PAYLOAD=$(jq -n --arg title "The website is online!" \
                     --arg description "<@&$ROLE_ID> The website is online!" \
                     --arg color "65280" \
                     --arg timestamp "$TIMESTAMP" \
                     --arg footer "webhook by @szvy on github - https://github.com/szvy/statuswebhook" \
                     '{
                        "content": "<@&'"$ROLE_ID"'>",
                        "embeds": [ {
                            "title": $title,
                            "description": $description,
                            "color": ($color | tonumber),
                            "timestamp": $timestamp,
                            "footer": {
                                "text": $footer
                            }
                        }]
                      }')

curl -H "Content-Type: application/json" -X POST -d "$JSON_PAYLOAD" "$DISCORD_WEBHOOK_URL" # sends a "site is up" message on start

while true; do
    RESPONSE=$(curl -s "https://www.operate.lol/api/check?site=PUTYOURSITEHERE") # put your website in the "site=" area, make sure to include https or http
    STATUS=$(echo "$RESPONSE" | jq -r '.status')

    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    if [[ "$STATUS" == "DOWN" && "$PREVIOUS_STATUS" != "DOWN" ]]; then # message for webhook if the site is down
        JSON_PAYLOAD=$(jq -n \
            --arg content "<@&$ROLE_ID>" \
            --arg title "Website is down! :(" \
            --arg description "The website is down! Trying to bring online..." \
            --arg color "16711680" \
            --arg timestamp "$TIMESTAMP" \
            --arg footer "webhook by @szvy on github - https://github.com/szvy/statuswebhook" \
            '{
                "content": $content,
                "embeds": [
                    {
                        "title": $title,
                        "description": $description,
                        "color": ($color | tonumber),
                        "timestamp": $timestamp,
                        "footer": {
                            "text": $footer
                        }
                    }
                ]
            }')

        curl -H "Content-Type: application/json" -X POST -d "$JSON_PAYLOAD" "$DISCORD_WEBHOOK_URL" # sends status to webhook

        systemctl start caddy # tries to start caddy
        if [[ $? -ne 0 ]]; then
            systemctl reload caddy # tries to reload caddy if it can't start it
        fi

    elif [[ "$STATUS" == "UP" && "$PREVIOUS_STATUS" == "DOWN" ]]; then # message for webhook if the site is up
        JSON_PAYLOAD=$(jq -n --arg title "The website is online!" \
                             --arg description "<@&$ROLE_ID> The website is online!" \
                             --arg color "65280" \
                             --arg timestamp "$TIMESTAMP" \
                             --arg footer "webhook by @szvy on github - https://github.com/szvy/statuswebhook" \
                             '{
                                "content": "<@&'"$ROLE_ID"'>",
                                "embeds": [ {
                                    "title": $title,
                                    "description": $description,
                                    "color": ($color | tonumber),
                                    "timestamp": $timestamp,
                                    "footer": {
                                        "text": $footer
                                    }
                                }]
                              }')

        curl -H "Content-Type: application/json" -X POST -d "$JSON_PAYLOAD" "$DISCORD_WEBHOOK_URL"
    fi

    PREVIOUS_STATUS="$STATUS"
    
    sleep 30 # how long until it checks again (i recommend keeping it at 30)
done
