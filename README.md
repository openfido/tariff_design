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
* `OUTPUT`: Specifies name of output file to store results of tariff simulation. Optional, default is `config.csv`. 
* `TARIFF_UTILITY`: Specifies utility company name. Values must be `Pacific Gas & Electric Co`, `San Diego Gas & Electric Co`, or `Southern California Edison Co`. If value not provided, will attempt simulation using `TARIFF_NAME` and `TARIFF_REGION`. 
* `TARIFF_NAME`: Specifies tariff name. Values must be `E-TOU-C3`, `E-7 Residential Time of Use Baseline`, `E-1`, `E-7`, `E-6`, `DR`, `EV-TOU-2`, `TOU-D-B`, or `TOU-D-TEV`. If value not provided, will attempt simulation using `TARIFF_UTILITY` and `TARIFF_REGION`.
* `TARIFF_REGION`: Specifies tariff region. Values must be `Region R`, `REGION P`, `REGION T`, `REGION Z`, `MOUTAIN BASELINE REGION`, `REGION 15`. 
* `TARIFF_INDEX_SPECIFIC`: Some tariffs need extra information to simulate. When encountered, provide this field with a corresponding value specified by the error message.

A model file (.glm) must be uploaded as well. `TODO`: 

Below is an example of `config.csv`:

| Header                  | Value
| ----------------------- | -----------------
| WEATHER_STATION         | CA-San_Francisco_Intl_Ap
| STARTTIME               | 2020-01-01T00:00:00-00:00
| STOPTIME                | 2020-01-01T00:00:00-12:00
| TIMEZONE                | PST+8PDT
| MODEL                   | model.glm
| OUTPUT                  | output.csv
| TARIFF_UTILITY          | Pacific Gas & Electric Co
| TARIFF_NAME             | E-TOU-C3
| TARIFF_REGION           | Region R

OUTPUTS
-------
`output.csv` or the name specified in `OUTPUT` of `config.csv` is generated in the output folder.  It will contain the following data:
* `Total Charges`: The amount incurred based on the configured simulation in the `Value` column, and the units 
* `Total Usage`: The electricty consumption in the `Value` column, and the units in `Units` column. 
* `Total Duration`: The duration of the simulation 
* `Total Power`: `TODO`

SEE ALSO
-------
* https://docs.gridlabd.us/_page.html?&doc=/GLM/Directive/Clock.md
