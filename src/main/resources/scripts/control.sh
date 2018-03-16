#!/bin/bash

# Time marker for both stderr and stdout
date 1>&2

CMD=$1
CMD_ROLE=$2
CMD_CONF=$3

DEFAULT_PRESTO_HOME_PREFIX=/data/presto-data
DEFAULT_PRESTO_HOME=$DEFAULT_PRESTO_HOME_PREFIX/$CMD_ROLE
NODE_PROPERTIES_PATH=$DEFAULT_PRESTO_HOME/node.properties
JVM_DUMMY_CONFIG_PATH=$CONF_DIR/etc/jvm.dummy.config
JVM_CONFIG_PATH=$CONF_DIR/etc/jvm.config
export JAVA_HOME=$CDH_PRESTO_JAVA_HOME
HIVE_CONF_PATH=$CONF_DIR/hive-conf

function log {
  timestamp=$(date)
  echo "$timestamp: $1"	   #stdout
  echo "$timestamp: $1" 1>&2; #stderr
}

function generate_jvm_config {
  log "generate_jvm_config $JVM_DUMMY_CONFIG_PATH to $JVM_CONFIG_PATH"
  if [ -f $JVM_DUMMY_CONFIG_PATH ]; then
    cat $JVM_DUMMY_CONFIG_PATH | perl -e '$line = <STDIN>; chomp $line; $configs = substr($line, (length "jvm.config=")); for $value (split /\\n/, $configs) { print $value . "\n" }' > $JVM_CONFIG_PATH
	log "success generate $JVM_CONFIG_PATH"
  fi
}

function copy_hdfs_config {
  cp $HIVE_CONF_PATH/core-site.xml $CONF_DIR/etc/catalog
  cp $HIVE_CONF_PATH/hdfs-site.xml $CONF_DIR/etc/catalog
}

function link_files {

  log "link_files $CDH_PRESTO_HOME $CONF_DIR $PRESTO_LIB $PRESTO_PLUGIN"
  cp -r $CDH_PRESTO_HOME/bin $CONF_DIR

  PRESTO_LIB=$CONF_DIR/lib
  if [ -L $PRESTO_LIB ]; then
    rm -f $PRESTO_LIB
  fi
  ln -s $CDH_PRESTO_HOME/lib $PRESTO_LIB

  PRESTO_PLUGIN=$CONF_DIR/plugin
  if [ -L $PRESTO_PLUGIN ]; then
    rm -f $PRESTO_PLUGIN
  fi
  ln -s $CDH_PRESTO_HOME/plugin $PRESTO_PLUGIN

  PRESTO_NODE_PROPERTIES=$CONF_DIR/etc/node.properties
  if [ -L $PRESTO_NODE_PROPERTIES ]; then
      rm -f $PRESTO_NODE_PROPERTIES
  fi
  ln -s $NODE_PROPERTIES_PATH $PRESTO_NODE_PROPERTIES
}

ARGS=()

case $CMD in

  (start_corrdinator)
    log "Start Presto Coordinator"
    link_files
    generate_jvm_config
    copy_hdfs_config
    ARGS=("--config")
    ARGS+=("$CONF_DIR/$CMD_CONF")
    ARGS+=("--data-dir")
    ARGS+=("$DEFAULT_PRESTO_HOME")
    ARGS+=("run")
    ;;

  (stop_corrdinator)
    log "Stop Presto Coordinator"
    link_files
    generate_jvm_config
    copy_hdfs_config
    ARGS=("--config")
    ARGS+=("$CONF_DIR/$CMD_CONF")
    ARGS+=("--data-dir")
    ARGS+=("$DEFAULT_PRESTO_HOME")
    ARGS+=("kill")
    ;;

  (start_discovery)
    log "Start Presto Discovery"
    link_files
    generate_jvm_config
    copy_hdfs_config
    ARGS=("--config")
    ARGS+=("$CONF_DIR/$CMD_CONF")
    ARGS+=("--data-dir")
    ARGS+=("$DEFAULT_PRESTO_HOME")
    ARGS+=("run")
    ;;
   
  (stop_discovery)
    log "Stop Presto Discovery"
	link_files
    generate_jvm_config
    copy_hdfs_config
    ARGS=("--config")
    ARGS+=("$CONF_DIR/$CMD_CONF")
    ARGS+=("--data-dir")
    ARGS+=("$DEFAULT_PRESTO_HOME")
    ARGS+=("kill")
    ;;

  (start_worker)
    log "Start Presto Worker"
    link_files
    generate_jvm_config
    copy_hdfs_config
    ARGS=("--config")
    ARGS+=("$CONF_DIR/$CMD_CONF")
    ARGS+=("--data-dir")
    ARGS+=("$DEFAULT_PRESTO_HOME")
    ARGS+=("run")
    ;;
  
  (stop_worker)
    log "Stop Presto Worker"
	link_files
    generate_jvm_config
    copy_hdfs_config
    ARGS=("--config")
    ARGS+=("$CONF_DIR/$CMD_CONF")
    ARGS+=("--data-dir")
    ARGS+=("$DEFAULT_PRESTO_HOME")
    ARGS+=("kill")
    ;;

  (init_node_properties)
    mkdir $DEFAULT_PRESTO_HOME_PREFIX
	rm -rf $DEFAULT_PRESTO_HOME
    mkdir $DEFAULT_PRESTO_HOME
    if [ ! -f "$NODE_PROPERTIES_PATH" ]; then
      echo "node.environment=production" > $NODE_PROPERTIES_PATH
      echo "node.data-dir=$DEFAULT_PRESTO_HOME" >> $NODE_PROPERTIES_PATH
      echo "node.id=`uuidgen`" >> $NODE_PROPERTIES_PATH
      log "create $NODE_PROPERTIES_PATH successfly"
    else
      log "$NODE_PROPERTIES_PATH is already created"
    fi
    exit 0
    ;;

  (*)
    log "Don't understand [$CMD]"
    ;;

esac

export PATH=$CDH_PRESTO_JAVA_HOME/bin:$PATH
cmd="$CONF_DIR/bin/launcher ${ARGS[@]}"
echo "Run [$cmd]"
exec $cmd
