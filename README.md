## Bash Timewarrior Extension
This bash script works as an [extension](https://timewarrior.net/docs/api/) to the commandline time-tracker [Timewarrior](https://timewarrior.net/). The timewarrior github repo can be found: https://github.com/GothenburgBitFactory/timewarrior

### Requirements/Dependencies
 - `timew`
 - `jq`
 - `soffice` (LibreOffice - only required if you set `XLSX_FILE="TRUE"`)

### Usage
1. Install timewarrior (go [here](https://timewarrior.net/docs/install/) for distro-specific options).
2. Initialize timewarrior by running `timew` and entering `yes` when prompted to create the 'extensions' directory.
3. Copy the `csv.sh` script to `~/.timewarrior/extensions/` and make executable (`chmod +x csv.sh`). Alternatively, clone the repo and create a symlink in the `~/.timewarrior/extensions/` directory back to wherever you cloned the script.
4. After creating some entries, run `timew report csv.sh [:week] [tags...]` to generate a report.

### Variables
|Variable|Description|Default|
|---|---|---|
|`REPORT_PATH`| The location to store the report created | $HOME/.timewarrior/timew-reports |
|`USER_NAME`| The name prefixing the report | $USER|
|`SEP`| The separator used in the CSV | ";"|
|`XLSX_FILE`| Creates an additional .xlsx file | "FALSE"|


### Additional Notes
This one of my first projects. I created this script as an exercise. I wanted to see if I could create a bash version of a Python extension - this one: https://github.com/lauft/timew-report

Please submit issues and any feedback you have if you are so inclined. I would like to make this extension more general and less specific to how I use it.

### Thanks!
Thank you to Tronde for your suggestions and ideas for improvement.