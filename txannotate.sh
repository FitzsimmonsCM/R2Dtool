#!/bin/bash

# written by AJ Sethi on 2022-05-26
# liftover bed-like sites from transcriptomic to genomic coordinates using a genome-appropriate annotation
# arg1: bed-like file with headers
# arg2: GTF
# arg3: output file

#!/bin/bash

# annotate cheui output from model II, model ii + prob, or CHEUI diff

# arg 1: cheui model (II, prob, or diff)
# arg 2: path to annotation (GTF format)
# arg 3: path to CHEUI output file
# arg 4: output file handle (will overwrite if already exists)

####################################################################################################
####################################################################################################
####################################################################################################

# setup

# fetch scriptpath for accesories
[ -n "${SCRIPTPATH+set}" ] || SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" || die "cannot get script path"; export SCRIPTPATH="${SCRIPTPATH}" # get the script path, adapted from https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself

# check for presence of the lift.R script which performs the liftover
script="${SCRIPTPATH}/lift.R"
[ -f "${script}" ] || die "cannot find Rscript"

# exit function
function usage() {
  printf "Usage:\narg 1: 6+ col bed-like file with headers\narg 2: path to annotation (GTF format)\narg 3: Desired output file handle (txannotate will overwrite if output file already exists)\n"
}; export -f usage

# die function
die() { printf "$(date +%F)\t$(date +%T)\t[scriptDied] txannotate died because it $*\n"; usage; exit 1; }; export -f die

##############################

# housekeeping

# check if no arguments supplied
if [ $# -eq 0 ]; then
  usage && exit 1
fi

# # check run version # not needed at present
# if [ "${1}" == "II" ]; then
#   export mode="II"
# elif [ "${1}" == "pval" ]; then
#   export mode="pval"
# elif [ "${1}" == "diff" ]; then
#   export mode="diff"
# else usage && exit 1
# fi

# check that the output file exists
export outFile=$3
touch ${outFile} || die "cannot make output file"

##############################

# process annotation

# process annotation
# check for transcript version identifier, which needs to be converted to a unified transcript ID, transcript version format
GTF=$2
GTFcount=$(cat $GTF | wc -l)
[ ${GTFcount} -gt "0" ] || die "User provided invalid GTF"

# check if the GTF has transcript_version and if so, clean it up
tversionCounts=$(cat ${GTF} | grep "transcript_version" | wc -l)
if [ ${tversionCounts} -gt "0" ];
then
  echo "converting gtf"
  cat $GTF | sed 's/"; transcript_version "/./' | grep "transcript_id" > ${outFile}.temp.gtf
else
  cat $GTF | grep "transcript_id" > ${outFile}.temp.gtf
fi

##############################

# convert CHEUI output to a 6-col bed file for annotation

# convert the CHEUI output to a bedlike format
if [ ${mode} == "II" ]; then
  echo "doing mode II"

elif [ ${mode} == "pval" ]; then
  echo "doing mode pval"
  cat $3 | tail -n +2 | tr "_" "\t" | awk '{ print $1"\t"$2+3"\t"$2+4"\t"$2+3";"$3";"$4";"$5";"$6";"$7"\t.\t+"}' > ${outFile}.tempbed
  mv ${outFile}.2 ${outFile}
elif [ ${mode} == "diff" ];
then
  echo "doing mode diff"
  cat $3 | tail -n +2 | tr "_" "\t" | awk '{ print $1"\t"$2+3"\t"$2+4"\t"$2+3";"$3";"$4";"$5";"$6";"$7";"$8";"$9";"$10"\t.\t+"}' > ${outFile}.tempbed
else
  die "invalid mode supplied"
fi

##############################

# call the annotate script

time Rscript ${script} ${outFile}.temp.gtf ${outFile}.tempbed ${outFile} ${mode} || die "annotate Rscript failed"

# append a hash to the output's col-names so that the bed file can still be opened in browsers
sed -i '1 i\#' ${outFile} # append a hash

# end script
echo "CHEUI annotate completed succesfully"