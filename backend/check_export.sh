#!/bin/sh

if ps fax|grep -v grep|grep -q exportloop
then
   : 
else
   sh /home/hot/bin/exportloop.sh
fi
