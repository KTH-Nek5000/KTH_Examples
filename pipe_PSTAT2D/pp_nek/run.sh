#!/bin/bash

casename='turbPipe'
nproc=1

if [ -f "logfile" ]; then
   rm logfile
fi
echo  $casename    >  SESSION.NAME
echo `pwd`'/' >>  SESSION.NAME
mpirun -np $nproc nek5000 >>logfile& 
sleep 3
rm -f SESSION.NAME                   
