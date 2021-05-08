# Home-assistant energy meter with Tasmota and portuguese e-redes
Quick adding your [e-redes](https://www.e-redes.pt/pt-pt) consumption data into your [Home-assistant](https://www.home-assistant.io/), via your MQTT.

Portuguese energy seller e-redes has implemented a set of energy meters that, through a HAN port, make available suficient information to create an interface to your MQTT, via a Tasmota special crafted firmware (FW). 

Starting with version 5.11.1e, Tasmota development of MQTT integration to Home-assistant was halted. So,aAfter instaling the phisical interface, each user has to create by hand each sensor to get the state information being sent to MQTT, wich is a fastidious thing. 

To send the information to the Home-Assistant configuration topic (homeassistant/light/kitchen/config), the idea was creating this script that will force feed the information manualy via [MQTT publication of the expected Home-assistant configurations message](https://www.home-assistant.io/docs/mqtt/discovery/).

The user intending to use this script has to configure the MQTT in Tasmota to publish to eredes/tasmota_[SENSOR IDENTITY]/state.

The FW will publish the following information: 
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:34:48","LANDYS":{"Tarifa":1}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:34:51","LANDYS":{"TotEneExp":0.0}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:34:54","LANDYS":{"Voltage_L1":242}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:34:54","LANDYS":{"Current_L1":1.4}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:34:57","LANDYS":{"Power_L1":219}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:34:57","LANDYS":{"PFactor_L1":0.610}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:34:57","LANDYS":{"Frequency":49.9}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:35:00","LANDYS":{"Energy_T1":2513.3}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:35:00","LANDYS":{"Energy_T2":1247.9}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:35:00","LANDYS":{"Energy_T3":2881.1}}
- eredes/tasmota_0D505E/SENSOR {"Time":"2021-04-19T00:35:00","LANDYS":{"Energy_TOT":6642}}

The result should be the creation of the following Entities per sensor:
- Tarifa
- TotEneExp
- Voltage_L1
- Current_L1
- Power_L1
- PFactor_L1
- Frequency
- Energy_T1
- Energy_T2
- Energy_T3
- Energy_TOT

