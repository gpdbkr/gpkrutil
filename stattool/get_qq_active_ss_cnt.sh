#!/bin/bash
source ~/.bashrc

## Extract number of active sessions from qq log
for i in `ls ${STATLOG}/qq.202*.txt`
do
echo $i
cat $i | egrep "^202|^\(" | sed 's/(/|/g' | sed 's/rows)/aa/g'| sed 's/row)/aa/g' | perl -pe "s/\n//g" | perl -pe 's/aa/\n/g' >> ${STATLOG}/qq_active_ss_cnt.log
done


## If you run the script in the statlog folder
#for i in `ls qq.2022*.txt`
#do
#echo $i
#cat $i | egrep "^2022|^\(" | sed 's/(/|/g' | sed 's/rows)/aa/g'| sed 's/row)/aa/g' | perl -pe "s/\n//g" | perl -pe 's/aa/\n/g' >> qq_active_ss.log
#done
