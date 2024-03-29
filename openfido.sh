#!/bin/sh
#
# GridLAB-D environment for OpenFIDO
#

TEMPLATE=tariff_design

trap on_error 1 2 3 4 6 7 8 11 13 14 15
# nounset: undefined variable outputs error message, and forces an exit
set -u
# errexit: abort script at first error
set -e
# print command to stdout before executing it:
set -x
# later, get the value and put it back
# gridlabd -D suppress_repeat_messages=FALSE

error()
{
    echo '*** ABNORMAL TERMINATION ***'
    echo 'See error Console Output stderr for details.'
    echo "See https://github.com/openfido/tariff_design for help"
    exit 1
}

# # configure template 
gridlabd template config set GITUSER slacgismo
gridlabd template config set GITREPO gridlabd-template
gridlabd template config set GITBRANCH add-tariff-design
gridlabd template config set DATADIR /model/us/ca/slac
# gridlabd template get tariff_design


echo "OPENFIDO_INPUT = $OPENFIDO_INPUT"
echo "OPENFIDO_OUTPUT = $OPENFIDO_OUTPUT"

if ! ls -1 $OPENFIDO_INPUT/*.glm; then
  echo "ERROR [openfido.sh]: input .glm file not found" > /dev/stderr
  error
fi

if ! ls -1 $OPENFIDO_INPUT/config.csv; then
  echo "ERROR [openfido.sh]: input config.csv file not found" > /dev/stderr
  error
fi


# default values for certain variables
MODEL_NAME_INPUT="model.glm"
OUTPUT_NAME_INPUT="output.csv"

# no default values
WEATHER_STATION=""
WEATHER_STATION_INDEX_NUMBER=0

echo "Copying input files to working directory"
cp -r $OPENFIDO_INPUT/* .

$(gridlabd --version=install)/bin/python3 -m pip install -r  requirements.txt

echo "Parsing config.csv..."
$(gridlabd --version=install)/bin/python3 csv_prepare.py 
echo "*** CONFIG.CSV PARSING SUCCESS ***"

if [ $? != 0 ]; then
    error
fi

echo "Matching weather station values..."
# rows can be in any order
while IFS=, read -r field1 field2 || [ -n "$field1" ]
do
    case "$field1" in
        "WEATHER_STATION")
            # Replaces weather station with correctly formatted weather station
            WEATHER_STATION=$field2
            WEATHER_STATION_LIST=$(gridlabd weather index $WEATHER_STATION)
            # Calling it twice. Storing it does not allow line counting. 
            WEATHER_STATION_INDEX_NUMBER=$(gridlabd weather index $WEATHER_STATION | wc -l)
            ;;
        "MODEL")
            MODEL_NAME_INPUT=$field2
            ;;
        "OUTPUT")
            OUTPUT_NAME_INPUT=$field2
            ;;
    esac
done < config.csv

# Handle based on weather stations returned 
if [ $WEATHER_STATION_INDEX_NUMBER -eq 1 ] ; then
    WEATHER_STATION_PARSED=$(basename "$WEATHER_STATION_LIST" .tmy3)
    gawk -i inplace -F ',' '{gsub(find,replace,$2); print}' find="$WEATHER_STATION" replace="$WEATHER_STATION_PARSED" OFS="," config.csv
elif [ $WEATHER_STATION_INDEX_NUMBER -gt 1 ] ; then
    # printf for more consistent \n
    printf "$WEATHER_STATION_LIST\n ERROR [TARIFF_DESIGN] : Could not find unique weather station. Please specify from list above:\n"  > /dev/stderr
    error
else 
    echo "ERROR [TARIFF_DESIGN] : Could not find matching weather stations. Please check capitalization and spelling."  > /dev/stderr
    error
fi
echo "*** WEATHER STATION UNIQUE MATCH SUCCESS ***"

echo "Getting tariff design template..."
gridlabd template get tariff_design

echo "Running gridlabd simulation..."
if [ -e clock.glm ]; then
    gridlabd $MODEL_NAME_INPUT clock.glm -t tariff_design
else 
    gridlabd $MODEL_NAME_INPUT -t tariff_design
fi

if [ $OUTPUT_NAME_INPUT != "output.csv" ]; then
    mv output.csv $OUTPUT_NAME_INPUT
fi

mv $OUTPUT_NAME_INPUT $OPENFIDO_OUTPUT
mv *.png $OPENFIDO_OUTPUT

echo '*** OUTPUTS ***'
ls -l $OPENFIDO_OUTPUT

echo '*** RUN COMPLETE ***'
echo 'See Data Visualization and Artifacts for results.'

echo '*** END ***'

exit 0
