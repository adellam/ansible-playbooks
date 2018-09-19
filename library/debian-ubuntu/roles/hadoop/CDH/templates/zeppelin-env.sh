#!/bin/bash

export ZEPPELIN_LOG_DIR="{{ cdh_zeppelin_home }}/log"
export ZEPPELIN_PID_DIR="{{ cdh_zeppelin_home }}/run"
export ZEPPELIN_WAR_TEMPDIR="{{ cdh_zeppelin_home }}/base_tmp/tmp"
export ZEPPELIN_NOTEBOOK_DIR="{{ cdh_zeppelin_home }}/notebook"

export ZEPPELIN_MEM="-Xms4096m -Xmx4096m"
export ZEPPELIN_INTP_MEM="-Xms4096m -Xmx4096m"

{% if cdh_zeppelin_use_spark2 %}
export SPARK_HOME=/opt/cloudera/parcels/SPARK2-2.2.0.cloudera2-1.cdh5.12.0.p0.232957/lib/spark2
{% else %}
# export MASTER=                                # Spark master url. eg. spark://master_addr:7077. Leave empty if you want to use local mode.
export SPARK_HOME=/opt/cloudera/parcels/CDH-5.9.3-1.cdh5.9.3.p0.4/lib/spark
{% endif %}
export DEFAULT_HADOOP_HOME=/opt/cloudera/parcels/CDH-5.9.3-1.cdh5.9.3.p0.4/lib/hadoop
export SPARK_JAR_HDFS_PATH=${SPARK_JAR_HDFS_PATH:-''}
export SPARK_LAUNCH_WITH_SCALA=0
export SPARK_LIBRARY_PATH=${SPARK_HOME}/lib
export SCALA_LIBRARY_PATH=${SPARK_HOME}/lib

SPARK_PYTHON_PATH=""
if [ -n "$SPARK_PYTHON_PATH" ]; then
  export PYTHONPATH="$PYTHONPATH:$SPARK_PYTHON_PATH"
fi

export HADOOP_HOME=${HADOOP_HOME:-$DEFAULT_HADOOP_HOME}

if [ -n "$HADOOP_HOME" ]; then
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${HADOOP_HOME}/lib/native
fi

SPARK_EXTRA_LIB_PATH=""
if [ -n "$SPARK_EXTRA_LIB_PATH" ]; then
  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SPARK_EXTRA_LIB_PATH
fi

export LD_LIBRARY_PATH

HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-$SPARK_CONF_DIR/yarn-conf}
HIVE_CONF_DIR=${HIVE_CONF_DIR:-/etc/hive/conf}
export MASTER=yarn-client
