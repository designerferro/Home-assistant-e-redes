#!/bin/bash
set -e
set -u
set -o pipefail

# Start secrets.sh file
# Change this values to match your Home-assistant
PROTOCOL="https"
HOST_IP_OR_NAME="YOUR_HOME_ASSISTANT"
PORT_NUMBER="8123"
HAToken="Home-Assistant-Token-Create_one_at_your_user"

# Change this to match your Tasmota Energy meter thing
EnergyMeterURI='http://YOUR_TASMOTA'
EnergyMeterMQTTTopic='tele/tasmota_'

# Change the values in this two arrays to match your variables and units of measure. One with all the variable names and another with unit of measure to be used for the entities
Variables=( Voltage_L1 Current_L1 Energy_T1 Energy_T2 Energy_T3 Energy_TOT Frequency PFactor_L1 Power_L1 TotEneExp );
UnitsOfMeasurement=( V A kWh kWh kWh kWh Hz pu W kWh );
mdiIcon=( chart-line chart-line chart-line chart-line chart-line chart-line chart-line chart-line chart-line chart-line );
# End secrets.sh file

# Create a file with the above variables (from star to end) and change this there.
# Remember to add the file to gitignore if you share your stuff in the cloud.
source ./secrets.sh

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
  d - Show data being sent to Home-assistant
  x - Show data being gathered

Usage:
Get energy data and show it at HASS http integration > $(basename "$0") -e
EOF
}

help () {

cat <<EOF
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
}

getData () {
  # Get the data from Tasmota
  EnergyData=$(curl -s $EnergyMeterURI/cs?c2=)
}

pushData () {
  # Re-arrange this stuff to send to Home-assistant
  i=0
  for varindex in "${Variables[@]}"; do
    # echo $varindex
    EnergyEntityData=$(echo $EnergyData | sed 's/tele\/tasmota/\n/g' | grep "$varindex" | tail -n 1 | sed 's/.*'"$varindex"'\"://g' | sed 's/}}//g' | sed 's/\ .*//g' | sed 's/}.*//g' )
    # Add data to home-assistant
    CurlResult=$(curl -s -k -X POST \
    -H "Authorization: Bearer $HAToken" \
    -H "Content-Type: application/json" \
    -d '{"state":"'$EnergyEntityData'","attributes":{"friendly_name":"'$varindex'","unit_of_measurement":"'"${UnitsOfMeasurement[${i}]}"'","icon":"mdi:'${mdiIcon[${i}]}'"}}' \
    $PROTOCOL://$HOST_IP_OR_NAME:$PORT_NUMBER/api/states/sensor.energy_"$varindex")
    echo "$i: $CurlResult"
    ((i=i+1))
  done
  exit 0

}

showData () {
  # Identify the variables from data
  i=0
  for varindex in "${Variables[@]}"; do
    # echo $varindex
    EnergyEntityData=$(echo $EnergyData | sed 's/tele\/tasmota/\n/g' | grep "$varindex" | tail -n 1 | sed 's/.*'"$varindex"'\"://g' | sed 's/}}//g' | sed 's/\ .*//g' | sed 's/}.*//g' )
    echo "$varindex $EnergyEntityData ${UnitsOfMeasurement[${i}]} mdi:${mdiIcon[${i}]}"
    ((i=i+1))
  done
  exit 0
}


while getopts 'dehux' OPTION; do
  case "$OPTION" in
    d)
      getData
      showData
      ;;
    e )
      getData
      pushData
      ;;
    h )
      usage
      help
      ;;
    u )
      usage
      ;;
    x )
      getData
      echo "$EnergyData"
      ;;
    \? )
      echo error "Invalid option: -$OPTARG" >&2  
      ;;
    * )
      echo error "$(basename "$0") needs a optiong." >&2
      usage
      ;;
  esac
done
shift "$(($OPTIND -1))"
