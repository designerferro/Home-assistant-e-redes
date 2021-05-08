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

# Change the values in this two arrays to match your variables and units of measure. One with all the variable names and another with unit of measure to be used for the entities
Variables=(Current_L1 Energy_T1 Energy_T2 Energy_T3 Energy_TOT Frequency PFactor_L1 Power_L1 TotEneExp);
UnitsOfMeasurement=(A kWh kWh kWh kWh Hz pu W kWh);

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
  m - Generate MQTT discovery package for Home-assistant

Usage:
Get energy data via HASS http integration > $(basename "$0") -e
Generate energy entities for HASS discovery > $(basename "$0") -m

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
    for i in "${!Variables[@]}";
    do
       if [[ "${Variables[$i]}" = "${EnergyEntity}" ]];
       then
                # Add data to home-assistant
                curl -s -k -X POST -H "Authorization: Bearer $HAToken" \
                -H "Content-Type: application/json" \
                -d '{"state": "'$EnergyEntityData'", "attributes": {"friendly_name":"'"$EnergyEntity"'","unit_of_measurement":"'"${UnitsOfMeasurement[${i}]}"'","icon": "mdi:chart-line"}}' \
                $PROTOCOL://$HOST_IP_OR_NAME:$PORT_NUMBER/api/states/sensor.energy_"$EnergyEntity" >/dev/null 2>&1
       fi;
    done

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
    for i in "${!Variables[@]}";
    do
       if [[ "${Variables[$i]}" = "${EnergyEntity}" ]];
       then
           echo $EnergyEntity $EnergyEntityData "${UnitsOfMeasurement[${i}]}"
       fi;
    done
  done

  exit 0
}

sendDiscoveryMQTT () {
  # Get the data from Tasmota
  EnergyData=$(curl -s $EnergyMeterURI/cs?c2=)
  # Identify the variables from data
  EnergyVars=( $(echo $EnergyData | sed 's/MQT/\n/g' | grep "$EnergyMeterMQTTTopic" | tail -n 50 | sed 's/.*{\"//' | sed 's/\".*//' | sort | uniq ) );

  # Re-arrange this stuff to send to Home-assistant
  for EnergyEntity in "${EnergyVars[@]}";
  do
    EnergyEntityData=$(echo $EnergyData | sed 's/MQT/\n/g' | grep $EnergyEntity | sed 's/.*:{//' | sed 's/}}.*//' | sed 's/.*://' | tail -n 1);
    EntityValue="$(./$(basename "$0") -d | grep $EnergyEntity | sed 's/.*\ //')"
    if [[ $EntityValue == *.* ]] ; then
        NumerType="float"
    else
        NumerType="int"
    fi
    HASSCreatEntity='homeassistant/sensor/energy_'$EnergyEntity'/config {"name":"'$EnergyEntity'","state_topic":"'$EnergyMeterMQTTTopic'","value_template":"{{value_json.LANDYS.'$EnergyEntity'}}","retain":"true","icon": "mdi:chart-line","device_class":"none"}' 
    payload=$(echo $HASSCreatEntity | sed 's/\ /\%20/g' | sed 's/\"/\%22/g' | sed 's/[{]/\%7B/g' | sed 's/[}]/\%7D/g' | sed 's/:/\%3A/g' | sed 's/,/\%2C/g' )
   curl $EnergyMeterURI/cm?cmnd=Publish%20$payload
  done

  exit 0
}

clearDiscoveryMQTT () {
  # Get the data from Tasmota
  EnergyData=$(curl -s $EnergyMeterURI/cs?c2=)
  # Identify the variables from data
  EnergyVars=( $(echo $EnergyData | sed 's/MQT/\n/g' | grep "$EnergyMeterMQTTTopic" | tail -n 50 | sed 's/.*{\"//' | sed 's/\".*//' | sort | uniq ) );

  # Re-arrange this stuff to send to Home-assistant
  for EnergyEntity in "${EnergyVars[@]}";
  do
    EnergyEntityData=$(echo $EnergyData | sed 's/MQT/\n/g' | grep $EnergyEntity | sed 's/.*:{//' | sed 's/}}.*//' | sed 's/.*://' | tail -n 1);
    curl -s $EnergyMeterURI/cm?cmnd=Publish%20'homeassistant/sensor/'"energy_$EnergyEntity"'/config'%20%20
  done

  exit 0
}


while getopts ':cdehm' OPTION; do
  case "$OPTION" in
    e)
      getEnergyData
      ;;
    h)
      usage
      ;;
    c)
      clearDiscoveryMQTT
      ;;
    d)
      showData
      ;;
    m)
      sendDiscoveryMQTT
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
