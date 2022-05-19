Pipeline status: [![validation](https://github.com/openfido/tariff_design/actions/workflows/main.yml/badge.svg)](https://github.com/openfido/tariff_design/actions/workflows/main.yml)

OpenFIDO Tariff Design pipeline
===============================

The `tariff_design` pipeline runs GridLAB-D tariff_design template.

PIPELINE
--------

Recommended pipeline settings:

| Setting                 | Recommended value
| ----------------------- | -----------------
| Pipeline name           | Tariff_Design
| Description             | Run GridLAB-D
| DockerHub Repository    | slacgismo/gridlabd:latest
| Git Clone URL (https)   | https://github.com/openfido/tariff_design
| Repository Branch       | develop-initial
| Entrypoint Script (.sh) | openfido.sh

INPUTS
------

The configuration file `config.csv` must be uploaded with the first row as `Header, Value`. The following parameters are recognized in `config.csv`:
* `WEATHER_STATION`: Specifies the weather station for the tariff simulation environment. No default.
* `STARTTIME`: Specifies the starting time for the tariff simulation. Recommended to use ISO8601 format. No default (subject to change). 
* `STOPTIME`: Specifies the ending time for the tariff simulation. Recommended to use ISO8601 format. No default (subject to change). 
* `TIMEZONE`: Specifies time zone of `STARTTIME` and `STOPTIME`. Recommended to use ISO8601 format. No default (subject to change). 
* `MODEL`: Specifies name of model for tariff simulation. File of the same name must be provided as input. Optional, default is `model.glm`. 
* `OUTPUT`: Specifies name of output file to store results of tariff simulation. Optional, default is `output.csv`. 
* `TARIFF_UTILITY`: Specifies utility company name. Values must be `Pacific Gas & Electric Co`, `San Diego Gas & Electric Co`, or `Southern California Edison Co`. If value not provided, will attempt simulation using `TARIFF_NAME` and `TARIFF_REGION`. 
* `TARIFF_NAME`: Specifies tariff name. Values must be `E-TOU-C3`, `E-7 Residential Time of Use Baseline`, `E-1`, `E-7`, `E-6`, `DR`, `EV-TOU-2`, `TOU-D-B`, or `TOU-D-TEV`. If value not provided, will attempt simulation using `TARIFF_UTILITY` and `TARIFF_REGION`.
* `TARIFF_REGION`: Specifies tariff region. Values must be `Region R`, `REGION P`, `REGION T`, `REGION Z`, `MOUTAIN BASELINE REGION`, `REGION 15`. 
* `TARIFF_INDEX_SPECIFIC`: Some tariffs need extra information to simulate. When encountered, provide this field with a corresponding value specified by the error message.

A model file (.glm) must be uploaded as well. Currently, these additional properties for class `meter` must be declared:
```
class meter 
{
	string monthly_charges;
	string monthly_usage;
	string monthly_power;
	double monthly_updated_charges[$];
	double monthly_updated_usage[kWh];
	double monthly_updated_power[W];
}
```

The `model.glm` file also requires various definitions and module declarations:

```
module powerflow;
module residential;
module tape;

#input "config.csv" -f config -t config

#set randomseed=1234

#define tariff_index=${TARIFF_INDEX}

clock {
	timezone ${TIMEZONE};
	starttime ${STARTTIME};
	stoptime ${STOPTIME};
}

#input "${WEATHER_STATION}.tmy3"
```
An example of a complete `model.glm` file is shown below:
```
module powerflow;
module residential;
module tape;

#input "config.csv" -f config -t config

#set randomseed=1234

#define tariff_index=${TARIFF_INDEX}

clock {
	timezone ${TIMEZONE};
	starttime ${STARTTIME};
	stoptime ${STOPTIME};
}

#input "${WEATHER_STATION}.tmy3"

#define PRIMARY_VOLTAGE=4800V
#define POWER_RATING=500
#define RESISTANCE=0.011
#define REACTANCE=0.02

class meter 
{
	string monthly_charges;
	string monthly_usage;
	string monthly_power;
	double monthly_updated_charges[$];
	double monthly_updated_usage[kWh];
	double monthly_updated_power[W];
}

object meter
{
	bustype "SWING";
	name "meter_1";	
	nominal_voltage "4800V";
	phases "ABCN";
}

object transformer_configuration {
	name "transformer_type1";
	connect_type "SINGLE_PHASE_CENTER_TAPPED";
  	install_type "PADMOUNT";
  	power_rating ${POWER_RATING};
  	primary_voltage ${PRIMARY_VOLTAGE};
  	secondary_voltage "120V";
  	resistance ${RESISTANCE};
  	reactance ${REACTANCE};
}

#for ID in ${RANGE 1, 20}

object transformer {
	name transformer_${ID};
  	phases "AS";
  	from "meter_1";
  	to "submeter_${ID}";
  	configuration "transformer_type1";
}
  
object triplex_meter
{
	name "submeter_${ID}";
	nominal_voltage "120V";
	phases "AS";
	object house
	{
		floor_area random.triangle(1000,2000);
		thermal_integrity_level "NORMAL";
		gas_enduses "WATERHEATER|DRYER|RANGE";
		heating_system_type "HEAT_PUMP";
	};
}

#done
```


Below is an example of `config.csv`:

| Header                  | Value
| ----------------------- | -----------------
| WEATHER_STATION         | CA-San_Francisco_Intl_Ap
| STARTTIME               | 2020-01-01T00:00:00-00:00
| STOPTIME                | 2021-01-15T00:00:00-12:00
| TIMEZONE                | PST+8PDT
| MODEL                   | model.glm
| OUTPUT                  | output.csv
| TARIFF_UTILITY          | Pacific Gas & Electric Co
| TARIFF_NAME             | E-TOU-C3
| TARIFF_REGION           | Region R

OUTPUTS
-------
`output.csv` or the name specified in `OUTPUT` of `config.csv` is generated in the output folder.  It will contain the following data by column:
* `Meter_ID`: The name of the meter as the index.
* `Date`: The year and month of the row values for a meter. For one row of meter and all triplex meters, values in this column will be `Total`.
* `Cost ($)`: The amount incurred based on the configured simulation.
* `Energy (kWh)`: The electricty consumption. 
* `Peak Power (W)`: The maximum power reached by a triplex meter during simulation duration. Meters do not record this value. 

Three bargraphs (.png) are generated in the output folder for each meter: one for `Cost ($)`, `Energy (kWh)`, and `Peak Power (W)`. The values of each meter for each month during the simulation duration will be plotted. 

Three histograms (.png) are generated in the output folder, plotting the distribution of `Cost ($)`, `Energy (kWh)`, and `Peak Power (W)` across all triplex meters. 


SEE ALSO
-------
* https://docs.gridlabd.us/_page.html?&doc=/GLM/Directive/Clock.md
