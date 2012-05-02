#!/bin/sh

if ps fax|grep -v grep|grep -q updateloop
then
   : 
else
   sh /home/hot/bin/updateloop.sh
fi
