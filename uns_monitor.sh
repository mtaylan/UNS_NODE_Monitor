#!/bin/bash
##
#
# UNS node check & telegram alert script
# @mtaylan
##

# Fail immediately if another instance is already running
export LC_ALL=C.UTF-8
script_name=$(basename -- "$0")

if pidof -x "$script_name" -o $$ >/dev/null;then
   echo "An another instance of this script is already running, please clear all the sessions of this script before starting a new session"
   exit 1
fi

# Check Required Commands
#
if ! command -v sar &> /dev/null
then
    echo "sar COMMAND could not be found!... Please install it"
    echo "sudo apt install sysstat"
    exit
fi

if ! command -v jq &> /dev/null
then
    echo "jq COMMAND could not be found!... Please install it"
    echo "sudo apt-get install jq -y"
    exit
fi


# Custom variables
#

#UNS NODE SETTINGS
UNS_NODE_IP=XXX.XXX.XXX.XXX (Your NODE Public IP)
HOSTNAME="My UNS_NODE"    (Your Node Name)

#Telegram BOT Settings
TOKEN=9999999999:AAAAAAAAAAAAAAAAAAk (replace with your Telegram BOT TOKEN)
CHAT_ID=9999999999  (replace with your Telegram Chat ID)
TELEGRAM_URL="https://api.telegram.org/bot$TOKEN/sendMessage"

#ALARM SETTINGS
SEND_ALERT_FLAG=true
SEND_ALERT_FLAG_SW=true
SEND_ALERT_FLAG_CPU=true
SEND_ALERT_FLAG_HDD=true
SEND_ALERT_FLAG_BLOCKS=true

#ALARM TRESHOLD VALUES   ( You can modify these values according to your needs. )
CPU_LOAD_CRITICAL=40.00
LATENCY_CRITICAL=500
ALIVE=`date +%M`
HDD_USE_CRITICAL=90
MAX_BLOCKS_BEHIND=15

#TMP FILES
FILE=/tmp/tmp_check_UNS_NODE
FILE_CPU=/tmp/tmp_check_UNS_NODE_CPU
FILE_SW=/tmp/tmp_check_UNS_NODE_SW
FILE_HDD=/tmp/tmp_check_UNS_HDD
FILE_BLOCKS=/tmp/tmp_check_UNS_BLOCKS

# End of Custom variables
#
#

#Check alert count latency
function check_alert_count
{
        if [ ! -f "$FILE" ]; then
            echo "1" > $FILE
            COUNTER=$(cat $FILE)
        else
            echo $(( $(cat $FILE) + 1 ))> $FILE
            COUNTER=$(cat $FILE)
        fi
 case $COUNTER in
          1) SEND_ALERT_FLAG=true ;;
          5) SEND_ALERT_FLAG=true ;;
          15) SEND_ALERT_FLAG=true ;;
          30) SEND_ALERT_FLAG=true ;;
          60) SEND_ALERT_FLAG=true ;;
          120) SEND_ALERT_FLAG=true ;;
          360) SEND_ALERT_FLAG=true ;;
          720) SEND_ALERT_FLAG=true ;;
          1440) SEND_ALERT_FLAG=true ;;
          *)  SEND_ALERT_FLAG=false ;;
        esac
}


#Check alert count cpu
function check_alert_count_cpu
{
        if [ ! -f "$FILE_CPU" ]; then
            echo "1" > $FILE_CPU
            COUNTER_CPU=$(cat $FILE_CPU)
        else
            echo $(( $(cat $FILE_CPU) + 1 ))> $FILE_CPU
            COUNTER_CPU=$(cat $FILE_CPU)
        fi

        case $COUNTER_CPU in
          1) SEND_ALERT_FLAG_CPU=true ;;
          5) SEND_ALERT_FLAG_CPU=true ;;
          15) SEND_ALERT_FLAG_CPU=true ;;
          30) SEND_ALERT_FLAG_CPU=true ;;
          60) SEND_ALERT_FLAG_CPU=true ;;
          120) SEND_ALERT_FLAG_CPU=true ;;
          360) SEND_ALERT_FLAG_CPU=true ;;
          720) SEND_ALERT_FLAG_CPU=true ;;
          1440) SEND_ALERT_FLAG_CPU=true ;;
          *)  SEND_ALERT_FLAG_CPU=false ;;
        esac
}

#Check alert count HDD
function check_alert_count_hdd
{
        if [ ! -f "$FILE_HDD" ]; then
            echo "1" > $FILE_HDD
            COUNTER_HDD=$(cat $FILE_HDD)
        else
            echo $(( $(cat $FILE_HDD) + 1 ))> $FILE_HDD
            COUNTER_HDD=$(cat $FILE_HDD)
        fi

        case $COUNTER_HDD in
          1) SEND_ALERT_FLAG_HDD=true ;;
          5) SEND_ALERT_FLAG_HDD=true ;;
          15) SEND_ALERT_FLAG_HDD=true ;;
          30) SEND_ALERT_FLAG_HDD=true ;;
          60) SEND_ALERT_FLAG_HDD=true ;;
          120) SEND_ALERT_FLAG_HDD=true ;;
          360) SEND_ALERT_FLAG_HDD=true ;;
          720) SEND_ALERT_FLAG_HDD=true ;;
          1440) SEND_ALERT_FLAG_HDD=true ;;
          *)  SEND_ALERT_FLAG_HDD=false ;;
        esac
}
#Check alert count SW
function check_alert_count_sw
{
        if [ ! -f "$FILE_SW" ]; then
            echo "1" > $FILE_SW
            COUNTER_SW=$(cat $FILE_SW)
        else
            echo $(( $(cat $FILE_SW) + 1 ))> $FILE_SW
            COUNTER_SW=$(cat $FILE_SW)
        fi

        case $COUNTER_SW in
          1) SEND_ALERT_FLAG_SW=true ;;
          5) SEND_ALERT_FLAG_SW=true ;;
          15) SEND_ALERT_FLAG_SW=true ;;
          30) SEND_ALERT_FLAG_SW=true ;;
          60) SEND_ALERT_FLAG_SW=true ;;
          120) SEND_ALERT_FLAG_SW=true ;;
          360) SEND_ALERT_FLAG_SW=true ;;
          720) SEND_ALERT_FLAG_SW=true ;;
          1440) SEND_ALERT_FLAG_SW=true ;;
          *)  SEND_ALERT_FLAG_SW=false ;;
        esac
}

#Check alert count blocks
function check_alert_count_blocks
{
        if [ ! -f "$FILE_BLOCKS" ]; then
            echo "1" > $FILE_BLOCKS
            COUNTER_BLOCKS=$(cat $FILE_BLOCKS)
        else
            echo $(( $(cat $FILE_BLOCKS) + 1 ))> $FILE_BLOCKS
            COUNTER_BLOCKS=$(cat $FILE_BLOCKS)
        fi

        case $COUNTER_BLOCKS in
          1) SEND_ALERT_FLAG_BLOCKS=true ;;
          5) SEND_ALERT_FLAG_BLOCKS=true ;;
          15) SEND_ALERT_FLAG_BLOCKS=true ;;
          30) SEND_ALERT_FLAG_BLOCKS=true ;;
          60) SEND_ALERT_FLAG_BLOCKS=true ;;
          120) SEND_ALERT_FLAG_BLOCKS=true ;;
          360) SEND_ALERT_FLAG_BLOCKS=true ;;
          720) SEND_ALERT_FLAG_BLOCKS=true ;;
          1440) SEND_ALERT_FLAG_BLOCKS=true ;;
          *)  SEND_ALERT_FLAG_BLOCKS=false ;;
        esac
}


#Telegram API to send notification for Latency.
function telegram_send
{
        if [ "$SEND_ALERT_FLAG" = true ] ; then
                echo " >>>>: sending $MESSAGE"
                curl --silent --max-time 13 --retry 3 --retry-delay 3 --retry-max-time 13 -X POST $TELEGRAM_URL -d chat_id=$CHAT_ID -d text="$MESSAGE"
        fi

}


#Telegram API to send notification for CPU.
function telegram_send_cpu
{
        if [ "$SEND_ALERT_FLAG_CPU" = true ] ; then
                echo " >>>>: sending $MESSAGE"
                curl --silent --max-time 13 --retry 3 --retry-delay 3 --retry-max-time 13 -X POST $TELEGRAM_URL -d chat_id=$CHAT_ID -d text="$MESSAGE"
        fi
}

#Telegram API to send notification for SW.
function telegram_send_sw
{
        if [ "$SEND_ALERT_FLAG_SW" = true ] ; then
                echo " >>>>: sending $MESSAGE"
                curl --silent --max-time 13 --retry 3 --retry-delay 3 --retry-max-time 13 -X POST $TELEGRAM_URL -d chat_id=$CHAT_ID -d text="$MESSAGE"
        fi
}

#Telegram API to send notificaiton for HDD.
function telegram_send_hdd
{
        if [ "$SEND_ALERT_FLAG_HDD" = true ] ; then
                echo " >>>>: sending $MESSAGE"
                curl --silent --max-time 13 --retry 3 --retry-delay 3 --retry-max-time 13 -X POST $TELEGRAM_URL -d chat_id=$CHAT_ID -d text="$MESSAGE"
        fi
}

#Telegram API to send notificaiton for BLOCKS.
function telegram_send_blocks
{
        if [ "$SEND_ALERT_FLAG_BLOCKS" = true ] ; then
                echo " >>>>: sending $MESSAGE"
                curl --silent --max-time 13 --retry 3 --retry-delay 3 --retry-max-time 13 -X POST $TELEGRAM_URL -d chat_id=$CHAT_ID -d text="$MESSAGE"
        fi
}

# Send Telegram test message
if [ "$1" == "test" ] ; then
        SEND_ALERT_FLAG_CPU=false
        MESSAGE="$(date) - [TEST] UNS node $HOSTNAME TEST message !!!.."
        echo " >>>> : $MESSAGE"
        telegram_send
        exit 0
fi

# NODE ALIVE  Message  sent every hour
if [[ $ALIVE == "00" ]]
then
MESSAGE="$(date) - [SYSTEM] [OK] UNS  node  $HOSTNAME ALIVE !!!.."
        echo " >>>> : $MESSAGE"
        telegram_send
        exit 0
    fi


#Check UNS NODE  health status with API call
HTTP_CODE=$(curl -s -w '%{http_code}' --connect-timeout 5 --max-time 10 -o /dev/null https://api.uns.network/api/peers/$UNS_NODE_IP)

CURL_STATUS=$?

echo " >>>> : $(date)"
echo " >>>> : TOKEN= $TOKEN"
echo " >>>> : CHAT_ID= $CHAT_ID"
echo " >>>> : HTTP_CODE= $HTTP_CODE"
echo " >>>> : CURL_STATUS= $CURL_STATUS"
echo " >>>> : FILE= $FILE"

# Check conditions
if [ "$CURL_STATUS" -eq 0 ]; then

        if [[ "$HTTP_CODE" -ne 200 ]] ; then
            check_alert_count
            MESSAGE="$(date) - [CRITICAL] [ALERT] UNS node is not running !!! #count:$COUNTER - returning http_code=$HTTP_CODE hostname=$HOSTNAME "
            echo " >>>> : $MESSAGE"
            telegram_send
        else
            echo " >>>> : UNS node $HOSTNAME is running!"

STATUS_HEALTHY=$(curl -sS https://api.uns.network/api/peers/$UNS_NODE_IP | jq -r '.data.latency')

        if [[ "$STATUS_HEALTHY" -lt $LATENCY_CRITICAL ]]; then
                MESSAGE="$(date) - [INFO] UNS node is healthy ! -  LATENCY(ms)=$STATUS_HEALTHY hostname=$HOSTNAME"
                echo " >>>> : $MESSAGE"
#               echo " >>>> : $STATUS_HEALTHY"
                if [ -f "$FILE" ]; then
                    echo "$FILE exists."
                    MESSAGE="$(date) - [INFO] [ALERT RESOLVED] UNS node is healthy again !!! -  LATENCY(ms)=$STATUS_HEALTHY hostname=$HOSTNAME"
                    rm $FILE
                    SEND_ALERT_FLAG=true
                    telegram_send
                fi
            else
                check_alert_count
                MESSAGE="$(date) - [CRITICAL] [ALERT LATENCY] UNS node is not healthy !!! #count:$COUNTER -  LATENCY(ms)=$STATUS_HEALTHY hostname=$HOSTNAME"
                echo " >>>> : $MESSAGE"
                telegram_send
            fi
        fi

else
        check_alert_count
        MESSAGE="$(date) - [CRITICAL] [ALERT] UNS node is not running #count:$COUNTER - hostname=$(hostname)"
        echo " >>>> : $MESSAGE"
        telegram_send

fi

        BLOCK_STATUS_UNS=$(curl -sS https://api.uns.network/api/blockchain | jq .'[].block.height')
         BLOCK_STATUS_NODE=$(curl -sS https://api.uns.network/api/peers/$UNS_NODE_IP |  jq  '.data.height')
	 BLOCKS_BEHIND="$(($BLOCK_STATUS_UNS - $BLOCK_STATUS_NODE))"

          if [[ "$BLOCKS_BEHIND" -lt $MAX_BLOCKS_BEHIND ]]; then
                MESSAGE="$(date) - [INFO] $HOSTNAME Block Size within Acceptable Limit! - Block Height at $HOSTNAME only $BLOCKS_BEHIND Blocks behind uns.network"
                echo " >>>> : Block Height at uns.network=$BLOCK_STATUS_UNS"
                echo " >>>> : Block Height at $HOSTNAME=$BLOCK_STATUS_NODE"
                echo " >>>> : Blocks BEHIND=$BLOCKS_BEHIND"
                echo " >>>> : $MESSAGE"

                if [ -f "$FILE_BLOCKS" ]; then
                    echo "$FILE_BLOCKS exists."
                    MESSAGE="$(date) - [INFO] [ALERT RESOLVED]  $HOSTNAME Blocks are  behind within acceptable limits ($BLOCKS_BEHIND Blocks) -  Limit is $MAX_BLOCKS_BEHIND Blocks "
                    rm $FILE_BLOCKS
                    SEND_ALERT_FLAG_BLOCKS=true
                    telegram_send_blocks
                fi
            else
                check_alert_count_blocks
                MESSAGE="$(date) - [CRITICAL] [ALERT BLOCKS] $HOSTNAME  Blocks are $BLOCKS_BEHIND blocks BEHIND from UNS.NETWORK!!! #count:$COUNTER_BLOCKS -  Limit is $MAX_BLOCKS_BEHIND blocks for $HOSTNAME"
                echo " >>>> : $MESSAGE"
                telegram_send_blocks
            fi


	SOFTWARE_VERSION=$(uns version |cut -d'/' -f3 |cut -d' ' -f1)
	 GITHUB_VERSION=$(curl -s https://github.com/unik-name/uns-cli/tags |grep /unik-name/uns-cli/releases/tag/ | head -n 1| cut -d'/' -f6 |cut -d'"' -f1)
         if [[ "$SOFTWARE_VERSION" == "$GITHUB_VERSION" ]]; then
                MESSAGE="$(date) - [INFO] Latest Software VERSION=$SOFTWARE_VERSION is installed on $HOSTNAME"
                echo " >>>> : $MESSAGE"
                echo " >>>> : installed uns-cli version $SOFTWARE_VERSION"
                echo " >>>> : uns-cli release $GITHUB_VERSION at GitHub"
                if [ -f "$FILE_SW" ]; then
                    echo "$FILE_SW exists."
                    MESSAGE="$(date) - [INFO] [ALERT RESOLVED] Latest Software uns-cli $SOFTWARE_VERSION installed on $HOSTNAME"
                    rm $FILE_SW
                    SEND_ALERT_FLAG_SW=true
                    telegram_send_sw
                fi
            else
                check_alert_count_sw
                MESSAGE="$(date) - [CRITICAL] [ALERT SOFTWARE VERSION] UNS SOFTWARE is OUTDATED! #count:$COUNTER_SW - INSTALLED VERSION=$SOFTWARE_VERSION  GITHUB VERSION=$GITHUB_VERSION hostname=$HOSTNAME"                
                echo " >>>> : $MESSAGE"
                telegram_send_sw
            fi

# check HDD capacity

        HDD_USAGE=$(df -H / | grep -vE 'Filesystem' | awk '{ print $5 " " $1 }')
        HDD_USED=$(echo $HDD_USAGE | awk '{ print $1}' | cut -d'%' -f1  )
        PARTITION=$(echo $HDD_USAGE | awk '{ print $2 }' )

        if [[ $HDD_USED -lt $HDD_USE_CRITICAL ]]; then
                MESSAGE="$(date) - [INFO] The partition \"$PARTITION\" on $HOSTNAME has used $HDD_USED%  of TOTAL HDD at $(date)"
                echo " >>>> : $MESSAGE"
                echo " >>>> : Partition: $PARTITION"
                echo " >>>> : HDD USED %: $HDD_USED"
                if [ -f "$FILE_HDD" ]; then
                    echo "$FILE_HDD exists."
                    MESSAGE="$(date) - [INFO] [ALERT RESOLVED] HDD Capacity is HIGHER than critical limit ($HDD_USE_CRITICAL%) on $HOSTNAME"
                    rm $FILE_HDD
                    SEND_ALERT_FLAG_HDD=true
                    telegram_send_hdd
                fi
            else
                check_alert_count_hdd
                MESSAGE="$(date) - [CRITICAL] [ALERT HDD CAPACITY] HDD capacity is lower than Critical Limit! #count:$COUNTER_HDD - CAPACITY USED=$HDD_USED%>"
                echo " >>>> : $MESSAGE"
                telegram_send_hdd
            fi



# check cpu usage

CPU_LOAD=`sar -P ALL 1 5 | grep "Average.*all" | awk -F" " '{printf "%.2f\n", 100 -$NF}'`

echo " >>>> : CPU_LOAD=$CPU_LOAD"
echo " >>>> : CPU_LOAD_CRITICAL=$CPU_LOAD_CRITICAL"


#if [[ $CPU_LOAD -gt $CPU_LOAD_CRITICAL ]];
#then

if (( $(echo "$CPU_LOAD $CPU_LOAD_CRITICAL" | awk '{print ($1 > $2)}') )); then
        PROC=`ps -eo pcpu,pid -o comm= | sort -k1 -n -r | head -1`
        echo " >>>> : callling check_alert_count_cpu "
        echo " >>>> : SEND_ALERT_FLAG_CPU : $SEND_ALERT_FLAG_CPU"
        check_alert_count_cpu
        MESSAGE="$(date) - [CRITICAL] [ALERT FIRING] UNS node high CPU usage problem !!! #count:$COUNTER_CPU - Please check your processess $PROC - Linux SAR Total CPU Usage : $CPU_LOAD % - hostname=$HOSTNAME"
        echo " >>>> : MESSAGE : $MESSAGE"
        echo " >>>> : SEND_ALERT_FLAG_CPU : $SEND_ALERT_FLAG_CPU"
        telegram_send_cpu
else
        if [ -f "$FILE_CPU" ]; then
                echo "$FILE_CPU exists."
                MESSAGE="$(date) - [INFO] [ALERT RESOLVED] UNS node normal CPU usage again !!! - Linux SAR Total CPU Usage : $CPU_LOAD % - hostname=$HOSTNAME"
                rm $FILE_CPU
                SEND_ALERT_FLAG_CPU=true
                echo " >>>> : $MESSAGE"
                telegram_send_cpu
       fi
fi
