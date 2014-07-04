#!/bin/bash

# Copyright 2013,2014 Marko Dimjašević, Simone Atzeni, Ivo Ugrina, Zvonimir Rakamarić
#
# This file is part of maline.
#
# maline is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# maline is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with maline.  If not, see <http://www.gnu.org/licenses/>.


die() {
    echo >&2 "$@"
    exit 1
}

# A root directory of the experiment
EXP_ROOT=$1

# A directory where log and graph files are
LOG_DIR=$2

CURR_DIR=$(pwd)
EXP_STARTED_FILE=$CURR_DIR/.maline-started
# Check if the script was started within an experiment directory
if [ -f $EXP_STARTED_FILE ] && [ -z $EXP_ROOT ] && [ -z $LOG_DIR ]; then
    EXP_ROOT=$CURR_DIR
    LOG_DIR=$CURR_DIR/android-logs
    kill $(cat $EXP_STARTED_FILE) &>/dev/null
else
    [ ! -z $EXP_ROOT ] || EXP_ROOT=$MALINE
    [ ! -z $LOG_DIR ] || LOG_DIR=$MALINE/log
fi

[ -d $EXP_ROOT ] || die "Non-existing experiment directory $EXP_ROOT!"
[ -d $LOG_DIR ] || die "Non-existing log directory $LOG_DIR!"

OUTPUT_FILE=$EXP_ROOT/features-file
rm -f $OUTPUT_FILE &>/dev/null

NUM_OF_FEATURES=$(head -1 `ls -1 $LOG_DIR/*graph | head -1`)
NUM_OF_APPS=$(ls -1 $LOG_DIR/*graph | wc -l)

echo "$NUM_OF_APPS $(($NUM_OF_FEATURES + 1))" >> $OUTPUT_FILE
# TODO: Remove the ratio from the input file
echo "90" >> $OUTPUT_FILE
# TODO: Remove the random flag from the input file
echo "1" >> $OUTPUT_FILE

# Separate goodware and malware files. Malware file names have to
# start with 64 hexadecimal digits
for FILE in $(ls -1 $LOG_DIR/*graph); do
    echo -n "Adding file $FILE... "
    CURR_NUM_OF_FEATURES=$(head -1 $FILE)
    [ $NUM_OF_FEATURES -eq $CURR_NUM_OF_FEATURES ] || die "Not all .graph files have the same number of features! Aborting."

    tail -1 $FILE >> $OUTPUT_FILE

    FIRST_PART=$(basename $FILE | awk -F"-" '{print $1}')
    if [[ $FIRST_PART =~ [0-9a-fA-F]{64} ]]; then
	echo "1" >> $OUTPUT_FILE
    else
	echo "0" >> $OUTPUT_FILE
    fi
    echo "done"
done

echo ""
echo "A feature file is in $OUTPUT_FILE"
