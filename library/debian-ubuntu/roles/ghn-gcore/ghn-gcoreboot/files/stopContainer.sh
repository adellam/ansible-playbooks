#!/bin/bash

cd $HOME
if [ -f .gcorerc ] ; then
    . .gcorerc
    gcore-stop-container
fi


