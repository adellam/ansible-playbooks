#!/bin/bash
export GLOBUS_LOCATION={{ globus_location }}
export PATH=$PATH:$GLOBUS_LOCATION/bin
export ANT_HOME={{ ant_location }}

nohup {{ globus_location }}/bin/gcore-start-container -p {{ ghn_port }}
