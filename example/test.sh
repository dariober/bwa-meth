# from http://tldp.org/LDP/abs/html/debugging.html#ASSERT
set -e -o nounset
assert ()                 #  If condition false,
{                         #+ exit from script
                          #+ with appropriate error message.
  E_PARAM_ERR=98
  E_ASSERT_FAILED=99


  if [ -z "$2" ]          #  Not enough parameters passed
  then                    #+ to assert() function.
    return $E_PARAM_ERR   #  No damage done.
  fi

  lineno=$2

  if [ ! $1 ] 
  then
    echo "Assertion failed:  \"$1\""
    echo "File \"$0\", line $lineno"    # Give name of file and line number.
    exit $E_ASSERT_FAILED
  # else
  #   return
  #   and continue executing the script.
  fi  
  echo "
[TEST]: '$1' PASSED at line:$lineno
"
}


rm -f ref.bwameth* bwa-meth.bam bwa-meth.bam.bai

python ../bwameth.py index ref.fa

##########################
# test read-group
##########################
rm -f bwa-meth.bam*
python ../bwameth.py --read-group $'@RG\tID:asdf\tSM:asdf' --reference ref.fa t_R1.fastq.gz t_R2.fastq.gz
n=`samtools view -H bwa-meth.bam | grep "@RG" | grep -cw "ID:asdf"`
assert "$n -eq 1" $LINENO
a=`samtools view  bwa-meth.bam | grep -c RG:Z:asdf`
b=`samtools view  bwa-meth.bam  | wc -l`
assert "$a -eq $b" $LINENO



##########################
# test normal alignment
##########################
python ../bwameth.py --reference ref.fa t_R1.fastq.gz t_R2.fastq.gz
assert " -e bwa-meth.bam " $LINENO
assert " -e bwa-meth.bam.bai " $LINENO

##########################
# test calmd
##########################
rm -r bwa-meth.bam bwa-meth.bam.bai
python ../bwameth.py --calmd --reference ref.fa t_R1.fastq.gz t_R2.fastq.gz
assert " -e bwa-meth.bam " $LINENO
assert " -e bwa-meth.bam.bai " $LINENO

count=`samtools view -cf2 bwa-meth.bam`

##########################
# test multiple fastq sets
##########################
# NOTE: here we repeat the same fastq, but you'd want diff ones from same sample
rm -f bwa-meth.bam*
python ../bwameth.py --reference ref.fa t_R1.fastq.gz,t_R1.fastq.gz t_R2.fastq.gz,t_R2.fastq.gz
assert " -e bwa-meth.bam " $LINENO
assert " -e bwa-meth.bam.bai " $LINENO

count2=`samtools view -cf2 bwa-meth.bam`
assert "$count -lt $count2" $LINENO

##########################
# test single end
##########################
rm -f bwa-meth.bam*
python ../bwameth.py --reference ref.fa t_R1.fastq.gz
assert " -e bwa-meth.bam " $LINENO
assert " -e bwa-meth.bam.bai " $LINENO
count=`samtools view -cf2 bwa-meth.bam`
assert "$count -eq 0" $LINENO
count=`samtools view -cF4 bwa-meth.bam`
assert "$count -gt 1000" $LINENO


##############################
# test single end, many fastqs
##############################
rm -f bwa-meth.bam*
python ../bwameth.py --reference ref.fa t_R1.fastq.gz,t_R1.fastq.gz
assert " -e bwa-meth.bam " $LINENO
assert " -e bwa-meth.bam.bai " $LINENO
count2=`samtools view -cf2 bwa-meth.bam`
assert "$count2 -eq 0" $LINENO
count2=`samtools view -cF4 bwa-meth.bam`
assert "$count2 -gt $count" $LINENO


echo  -e "\nCan add custom extra arguments"
# -----------------------------------
rm -f bwa-meth.bam*
python ../bwameth.py -x "-U 200 -T 30 -B 2 -L 20 -CM -k 8" --reference ref.fa t_R1.fastq.gz t_R2.fastq.gz 2> bwameth.log
echo 'Is exit code 0?'
if [[ "0" == "$?" ]]
then
    echo "PASS"
else
    echo "*** FAILED ***"
fi

extra=`grep 'bwa mem -U 200 -T 30 -B 2 -L 20 -CM -k 8 -p -R' bwameth.log`
echo "bwa ran with extra args"
if [[ $extra != "" ]]
then
    echo "PASS"
else
    echo "*** FAILED ***"
fi
rm bwameth.log

echo "Success: ALL Tests PASS"
