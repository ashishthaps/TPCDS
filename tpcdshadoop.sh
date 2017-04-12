#!/bin/bash
git clone https://github.com/hdinsight/tpcds-datagen-as-hive-query/ && cd tpcds-datagen-as-hive-query
hdfs dfs -copyFromLocal resources /tmp
byobu
beeline -u "jdbc:hive2://`hostname -f`:10001/;transportMode=http" -n "" -p "" -i settings.hql -f TPCDSDataGen.hql -hiveconf SCALE=1000 -hiveconf PARTS=1000 -hiveconf LOCATION=/HiveTPCDS/ -hiveconf TPCHBIN=`grep -A 1 "fs.defaultFS" /etc/hadoop/conf/core-site.xml | grep -o "wasb[^<]*"`/tmp/resources  
beeline -u "jdbc:hive2://`hostname -f`:10001/;transportMode=http" -n "" -p "" -i settings.hql -f ddl/createAllORCTables.hql -hiveconf ORCDBNAME=tpcds_orc -hiveconf SOURCE=tpcds
beeline -u "jdbc:hive2://`hostname -f`:10001/;transportMode=http" -n "" -p "" -i settings.hql -f ddl/analyze.hql -hiveconf ORCDBNAME=tpcds_orc 
for f in queries/*.sql; do for i in {1..1} ; do STARTTIME="`date +%s`";  beeline -u "jdbc:hive2://`hostname -f`:10001/tpcds_orc;transportMode=http" -i settings.hql -f $f  > $f.run_$i.out 2>&1 ; ENDTIME="`date +%s`"; echo "$f,$i,$STARTTIME,$ENDTIME,$(($ENDTIME-$STARTTIME))" >> times_orc.csv; done; done;
