#!/bin/bash

cd $HOME
if [ -f .gcorerc ] ; then
    . .gcorerc

    gcore-start-container
fi
