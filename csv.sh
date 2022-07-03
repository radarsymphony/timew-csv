#!/bin/bash

## ENV Variables & Defaults
REPORT_PATH="${REPORT_PATH:-$HOME/.timewarrior/timew-reports}"
USER_NAME="${USER_NAME:-${USER}}"
SEP="${SEP:-;}"
XLSX_FILE="${XLSX_FILE:-FALSE}"

## Script Variables
total_seconds=0
tmp_file_name="${USER_NAME}-$(date +%F)-tmp.csv"
tmp_json=$(mktemp)
tmp_csv=$(mktemp)

## Create weekly log file
mkdir -p "${REPORT_PATH}"
[[ -e "${REPORT_PATH}"/"${tmp_file_name}" ]] && rm "${REPORT_PATH}"/"${tmp_file_name}"
touch "${REPORT_PATH}"/"${tmp_file_name}" 

## Dependencies
check_dependencies() {
    ## An array of dependencies
    depends=("timew" "jq")
    [[ "${XLSX_FILE}" == "TRUE" ]] && depends+=("soffice")
    ## Iterate through to verify that they are executable
    for dep in "${depends[@]}"; do
        if ! command -v "${dep}" >/dev/null 2>&1 ; then
            echo "the dependency '${dep}' was not found"
            exit 1
        fi  
    done
}

## Parsing the standard in from 'timew'
parse_timew_data() {
    data_section=false

    ## Iterate through timew output looking for json
    while read -r line; do
        if [[ "${data_section}" == "true" ]]; then
            echo "${line}" >> "${tmp_json}"
        fi

        ## When program reaches blank line denoting json, begin adding it to json file
        [[ -z ${line} ]] && data_section=true
    done <"${1}"
}

## Parse the Json created from 'timew'
convert_json_to_csv() {
    ## Hardcoded column headers in case the first row has an empty annotation
    jq -r '["id","start","end","tags","annotation"] as $keys | $keys, map([.[ $keys[] ] | walk(if type == "array" then join(" ") else . end) ])[] | @csv' "${tmp_json}" > "${tmp_csv}"
}

## Format Report
reformat_csv() {
    ## Add a header to the csv file and remove any old contents if old file exists
    echo "ID${SEP}Tasks/Tags${SEP}Remarks/Notes${SEP}Date${SEP}Start${SEP}End${SEP}Duration${SEP}Totals" > "${REPORT_PATH}"/"${tmp_file_name}"

    ## Iterate through tmp csv
    while IFS="," read -r id start end tags notes; do

        ## Modify and generate values for CSV
        seconds=$( calc_duration "${start}" "${end}" )
        duration=$( convert_secs "${seconds}" )
        hmn_start=$( convert_time_to_human "${start}" )
        hmn_end=$( convert_time_to_human "${end}" )
        _date=$( convert_time_to_date "${start}" )
        total_seconds=$((total_seconds + seconds))

        ## Add modified values to csv
        echo "${id}${SEP}${tags}${SEP}${notes}${SEP}${_date}${SEP}${hmn_start}${SEP}${hmn_end}${SEP}${duration}" >> "${REPORT_PATH}"/"${tmp_file_name}"

    done < <(tail -n +2 "${tmp_csv}")

    ## Add total hours to CSV on last line
    echo "${SEP}${SEP}${SEP}${SEP}${SEP}${SEP}${SEP}$(convert_secs ${total_seconds})${SEP}" >> "${REPORT_PATH}"/"${tmp_file_name}"
}

## Utility functions
convert_time_to_unix(){
    date -u -d "$(echo ${1//\"/} | sed -r 's|(.*)T(..)(..)(..)|\1 \2:\3:\4|; s|Z||')" +%s
}

convert_time_to_human() {
    unix_sec=$(convert_time_to_unix "${1}")
    date -d @"${unix_sec}" +%T 
}

convert_time_to_date() {
    unix_sec=$(convert_time_to_unix "${1}")
    date -d@"${unix_sec}" +%F
}

calc_duration(){
    begin=$(convert_time_to_unix "${1}")
    finish=$(convert_time_to_unix "${2}")
    echo "$(($finish - $begin))"
}

convert_secs() {
    ((h=${1}/3600))
    ((m=(${1}%3600)/60))
    ((s=${1}%60))
    echo "${h}h ${m}m"

    ## Alternative method?
    ###echo "${1}" | awk '{printf "%02dh %02dm %02ds", $1/3600, ($1/60)%60, $1%60}'
}

update_file_name() {
    report_name="${USER_NAME}-$( head "${REPORT_PATH}/${tmp_file_name}" -n2 | tail -n1 | cut -d';' -f 4 )-log.csv"
    mv "${REPORT_PATH}"/"${tmp_file_name}" "${REPORT_PATH}"/"${report_name}"
}

convert_to_xlsx() {
    soffice --headless --infilter="CSV:59" --convert-to xlsx --outdir "${REPORT_PATH}" "${REPORT_PATH}"/"${report_name}"
}

## Main Processes
check_dependencies
parse_timew_data "${1:-/dev/stdin}"
convert_json_to_csv 
reformat_csv
update_file_name
[[ "${XLSX_FILE}" == "TRUE" ]] && convert_to_xlsx || \
    echo -n "${REPORT_PATH}"/"${report_name}"

clean_up() {
    rm "${tmp_csv}"
    rm "${tmp_json}"
}

trap clean_up exit