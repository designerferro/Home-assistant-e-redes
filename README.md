# Home-assistant energy meter with Tasmota and portuguese e-redes
Quick adding your [e-redes](https://www.e-redes.pt/pt-pt) consumption data into your [Home-Assistant](https://www.home-assistant.io/), via [HTTP integreation from Home-Assistant](https://www.home-assistant.io/integrations/http/).

Portuguese energy seller e-redes has implemented a set of energy meters that, through a HAN port, make available suficient information. We are using a [Tasmota special crafted firmware (FW)](https://github.com/nikito7/edp_box_modbus/tree/dev/tasmota) to do this. 

This is a Bash script that uses curl to get everything done.

The FW will publish information much like the one bellow in a URL: 
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

This script looks for the variables, gets the last data for each variable and posts it to your Home-Assistant via HTTP:
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