#!/bin/bash

# Check if SABER_HOME is set
if [ -z "$SABER_HOME" ]; then
	echo "error: \$SABER_HOME is not set"
	exit 1
fi

# Source common functions
. "$SABER_HOME"/scripts/common.sh

# Source configuration parameters
. "$SABER_HOME"/scripts/saber.conf

USAGE="usage: aggregation.sh [ --batch-size ] [ --window-type ] [ --window-size ] [ --window-slide ] [ --input-attributes ] [ --aggregate-expression ] [ --groups-per-window ] [ --tuples-per-insert ]"

CLS="uk.ac.imperial.lsds.saber.experiments.microbenchmarks.TestAggregation"

#
# Application-specific arguments
#
# Query task size (default is 1048576)
BATCH_SIZE=

# Window type: "row" for count-based or "range" for time-based windows (default is "row")
WINDOW_TYPE=

# Window size (default is 1)
WINDOW_SIZE=

# Window slide (default is 1)
WINDOW_SLIDE=

# Number of input attributes (default is 6)
INPUT_ATTRS=

# One or more of avg, cnt, min or max, separated by commas (default is "cnt")
AGGREGATE_EXPRESSION=

# Default is 0
GROUPS_PER_WINDOW=

# Number of tuples per insert (default is 32768)
TUPLES_PER_INSERT=

# Parse application-specific arguments

while :
do
	case "$1" in
		--batch-size)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		BATCH_SIZE="$2"
		shift 2
		;;
		--window-type)
		saberOptionInSet "$1" "$2" "row" "range" || exit 1
		WINDOW_TYPE="$2"
		shift 2
		;;
		--window-size)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		WINDOW_SIZE="$2"
		shift 2
		;;
		--window-slide)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		WINDOW_SLIDE="$2"
		shift 2
		;;
		--input-attributes)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		INPUT_ATTRS="$2"
		shift 2
		;;
		--aggregate-expression)
		#
		AGGREGATE_EXPRESSION="$2"
		shift 2
		;;
		--groups-per-window)
		saberOptionIsInteger "$1" "$2" || exit 1
		GROUPS_PER_WINDOW="$2"
		shift 2
		;;
		--tuples-per-insert)
		saberOptionIsPositiveInteger "$1" "$2" || exit 1
		TUPLES_PER_INSERT="$2"
		shift 2
		;;
		-h | --help)
		echo $USAGE
		exit 0
		;;
		--*) 
		# Check if $1 is a system configuration argument	
		saberParseSysConfArg "$1" "$2"
		errorcode=$?
		if [ $errorcode -eq 0 ]; then
			shift 2
		elif [ $errorcode -eq 1 ]; then
			# $1 was a valid system configuration argument
			# but with a wrong value
			exit 1
		else
			echo "error: invalid option: $1" >&2
			exit 1
		fi
		;;
		*) # done, if string is empty
		if [ -n "$1" ]; then
			echo "error: invalid option: $1"
			exit 1
		fi
		break
		;;
	esac
done

#
# Configure app args
#
APPARGS=""

#
# Configure app args
#
APPARGS=""

[ -n "$BATCH_SIZE" ] && \
APPARGS="$APPARGS --batch-size $BATCH_SIZE"

[ -n "$WINDOW_TYPE" ] && \
APPARGS="$APPARGS --window-type $WINDOW_TYPE"

[ -n "$WINDOW_SIZE" ] && \
APPARGS="$APPARGS --window-size $WINDOW_SIZE"

[ -n "$WINDOW_SLIDE" ] && \
APPARGS="$APPARGS --window-slide $WINDOW_SLIDE"

[ -n "$INPUT_ATTRS" ] && \
APPARGS="$APPARGS --input-attributes $INPUT_ATTRS"

[ -n "$GROUPS_PER_WINDOW" ] && \
APPARGS="$APPARGS --groups-per-window $GROUPS_PER_WINDOW"

[ -n "$AGGREGATE_EXPRESSION" ] && \
APPARGS="$APPARGS --aggregate-expression $AGGREGATE_EXPRESSION"

[ -n "$TUPLES_PER_INSERT" ] && \
APPARGS="$APPARGS --tuples-per-insert $TUPLES_PER_INSERT"

#
# Configure system args
#
SYSARGS=""

saberSetSysArgs

#
# Execute application
errorcode=0
#
# if --experiment-duration is set, then we should run the experiment
# in the background.
#
if [ -z "$SABER_CONF_EXPERIMENTDURATION" ]; then
	
	"$SABER_HOME"/scripts/run.sh \
	--mode foreground \
	--class $CLS \
	-- $SYSARGS $APPARGS
else
	#
	# Find the experiments duration is seconds
	#
	interval="$SABER_CONF_PERFORMANCEMONITORINTERVAL"
	[ -z "$interval" ] && interval="1000" # in msec; the default interval
	
	# Duration is `interval` units
	units="$SABER_CONF_EXPERIMENTDURATION"
	
	# Duration in msecs
	msecs=`echo "$units * $interval" | bc`
	
	# Duration is seconds
	duration=`echo "scale=0; ${msecs} / 1000" | bc`
	
	# Round up
	remainder=`echo "${msecs} % 1000" | bc`
	if [ $remainder -gt 0 ]; then
		let duration++
	fi
	
	"$SABER_HOME"/scripts/run.sh --mode background --alias "aggregation" --class $CLS --duration $duration -- $SYSARGS $APPARGS
	errorcode=$?
fi

exit $errorcode

