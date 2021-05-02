#!/bin/bash
set -e
set -u
set -o pipefail

# Change this values to match your Home-assistant
PROTOCOL="https"
HOST_IP_OR_NAME="YOUR_HOME_ASSISTANT"
PORT_NUMBER="8123"
HAToken="Home-Assistant-Token-Create_one_at_your_user"

# Change this to match your Tasmota Energy meter thing
EnergyMeterURI='http://YOUR_TASMOTA'
EnergyMeterMQTTTopic='tele/tasmota_'

##########################################
# Don't change anything bellow this line.#
# You break it, you fix it.              #
##########################################

usage () {

cat <<EOF

This is a simple script to make publishing your home energy consumption data to Home-Assistant \
easier without any configuration in YAML.
The script must be added to run every n minutes so it gets the values from the energy meter.

  Options
  -------
  h - This help text
  e - Get the energy data and publish it to your home-assistant
  d - Show data being gathered

Usage:
Get energy data > $(basename "$0") -e

HOW-TO GET THE DATA FROM THE ENERGY METER
-----------------------------------------
Follow this instructions here https://forum.cpha.pt/t/integrar-contadores-inteligentes-da-edp-em-home-assistant/4953

HOW-TO configure communication to your Home-assistant
-----------------------------------------------------
Configure the bellow variables at the top of this script to communicate with your Home-assistant:
--> PROTOCOL="https" <-- Accepts only "https".
--> HOST_IP_OR_NAME="localhost" <-- Usually "localhost" worked fine, but not anymore. Enter the full address like "myserver.myhouse.dyndns.net".
--> PORT_NUMBER="8123" <-- This is the port number your Home-assistant is listening.
--> HAPASSWORD="theverylongapikey" <-- Enter the new Long-Lived Access Tokens password you just got from your home HA profile.
EOF

exit 0
}


getEnergyData () {
	# Get the data from Tasmota
	EnergyData=$(curl -s $EnergyMeterURI/cs?c2=)
	# Identify the variables from data
	EnergyVars=( $(echo $EnergyData | sed 's/MQT/\n/g' | grep "$EnergyMeterMQTTTopic" | tail -n 50 | sed 's/.*{\"//' | sed 's/\".*//' | sort | uniq ) );

	# Re-arrange this stuff to send to Home-assistant
	for EnergyEntity in "${EnergyVars[@]}";
	do
		EnergyEntityData=$(echo $EnergyData | sed 's/MQT/\n/g' | grep $EnergyEntity | sed 's/.*:{//' | sed 's/}}.*//' | sed 's/.*://' | tail -n 1);
                # Add data to home-assistant
                curl -s -k -X POST -H "Authorization: Bearer $HAToken" \
                -H "Content-Type: application/json" \
                -d '{"state": "'$EnergyEntityData'", "attributes": {"friendly_name":"'"$EnergyEntity"'","icon": "mdi:chart-line"}}' \
                $PROTOCOL://$HOST_IP_OR_NAME:$PORT_NUMBER/api/states/sensor.energy_"$EnergyEntity" >/dev/null 2>&1
	done

  exit 0
}

showData () {
	# Get the data from Tasmota
	EnergyData=$(curl -s $EnergyMeterURI/cs?c2=)
	# Identify the variables from data
	EnergyVars=( $(echo $EnergyData | sed 's/MQT/\n/g' | grep "$EnergyMeterMQTTTopic" | tail -n 50 | sed 's/.*{\"//' | sed 's/\".*//' | sort | uniq ) );

	# Re-arrange this stuff to send to Home-assistant
	for EnergyEntity in "${EnergyVars[@]}";
	do
		EnergyEntityData=$(echo $EnergyData | sed 's/MQT/\n/g' | grep $EnergyEntity | sed 's/.*:{//' | sed 's/}}.*//' | sed 's/.*://' | tail -n 1);
		echo $EnergyEntity $EnergyEntityData
	done

  exit 0
}

while getopts ':deh' OPTION; do
  case "$OPTION" in
    e)
      getEnergyData
      ;;
    h)
      usage
      ;;
    d)
      showData
      ;;
    ?)
      usage
      exit 1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"
