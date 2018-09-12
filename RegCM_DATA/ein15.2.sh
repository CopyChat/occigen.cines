#!/bin/bash - 
#===============================================================================
#
#          FILE: ein15.sh
# 
         USAGE="./ein15.sh [opt] + [ start ] + [ end ]"
# 
#   DESCRIPTION: to download ein15 data from ICTP website.
# 				 http://clima-dods.ictp.it/data/d8/cordex/
# 
#       OPTIONS: --- -t for TEST
#        			 -n for number of precess allowed simutaniously. 
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Tang (Tang), tangchao90908@sina.com
#  ORGANIZATION: KLA
#       CREATED: 06/26/2014 03:24:26 PM RET
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
source ~/Code/functions.sh
#=================================================== 
#Nproc=${#param[@]}  			  # number of processes allowed running in background
Nproc=5  			  # number of processes allowed running in background
TEST=0
#=================================================== 
while getopts ":n:t" opt; do
	case $opt in
		t) TEST=1 ;;
		n) Nproc=$OPTARG;;
		\?) echo $USAGE && exit 1
	esac
done

shift $(($OPTIND - 1))
#=================================================== 
Start=${1:-1979};End=${2:-2015} 		#  default
Njob=$((20 * ( $End - $Start) ))  # total number of jobs
param=("air" "hgt" "rhum" "uwnd" "vwnd")
Nproc=${#param[@]}  			  # number of processes allowed running in background


#=================================================== 
function CMD    # for test
{
	n=$((RANDOM % 5 + 2 ))
	sleep $n
	echo process id = $!, sleep $n second...
#	color -n 1 7 " Downloading: ";color -n 7 4 " $year "
	#color -n 7 5 " $param "; color 7 2 " $Time "
}

#=================================================== 
function Download  					# from ICTP
{
	address=http://clima-dods.ictp.it/Data/RegCM_Data/EIN15/
	EIN15=/scratch/cnt0027/lep7640/ctang/RegCM_DATA/EIN15
	color -n 1 2 " ✪✪✪✪✪✪✪✪✪✪✪✪ ⚽︎ ⚽︎ ⚽︎ ⚽︎ ⚽︎ ⚽︎ ⚽︎  ✪✪✪✪✪✪✪✪✪✪✪✪ Process ID: $! "
	color -n 1 7 " Downloading: ";color -n 7 4 " $1 "
	color -n 7 5 " $2 "; color -n 4 2 " $3 "
	color 1 7 " nc ..." 		 # :TODO:06/27/2014 03:44:45 PM RET:Tang: connection with parent process
	wget -c ${address}$1/$2.$1.$3.nc -P $EIN15/$1/ 
#	wget -c ${address}$1/$2.$1.$3.nc -P $EIN15/$1/ > $EIN15/$1/$2.$1.$3.log 2>&1
}

#================================================ "first in first out" method
Pfifo="~/.tmp/$$.fifo" # make a pipe line  named as PID
mkfifo $Pfifo   
exec 6<>$Pfifo # open the pipe as written and read
			   # file descriptor could be number between 0-9 but 0,1,2,5
rm -f $Pfifo   # not necessary

### put $Nproc space lines as tickets to run in background
for (( i=0; i<$Nproc; i++)); do
	echo
done >&6

#=================================================== 
### submit the jobs
j=0   # for test
for year in $(eval echo $(seq $Start $End))
do
	for Time in 00 06 12 18
	do
		for param in air hgt rhum uwnd vwnd
		do
			read -u6  			  # get a ticket
			if [ "$TEST" = "1" ]; then color 7 1 "-t for TEST!";
				( CMD $j; sleep 1; echo >&6 ) &
			else
				( Download $year $param $Time; sleep 3; echo >&6 ) &
			fi
#				echo >&6 		  # give back the ticket for next job
				((j++)) 		  # for test
				sleep 3          # this time for each printing messages
		done
	done
done

wait      # wait for all the subprocesses in these years DONE.

exec 6>&- # dellet file descriptor

