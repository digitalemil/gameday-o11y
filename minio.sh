#!/bin/bash

export MINIOLOGFOLDER=$LOGFOLDER/minio
mkdir -p $MINIOLOGFOLDER

/opt/minio/minio server /mnt/data --console-address :38991 >$MINIOLOGFOLDER/minio.log 2>&1 &
sleep 8

/opt/minio/mc --insecure alias set admin http://localhost:9000/ minioadmin minioadmin  >$MINIOLOGFOLDER/mc1.out 2>&1  
/opt/minio/mc --insecure admin user add admin cockroachdb cockroachdb >$MINIOLOGFOLDER/mc2.out 2>&1  
/opt/minio/mc --insecure admin policy attach admin readwrite --user cockroachdb >$MINIOLOGFOLDER/mc3.out 2>&1  
/opt/minio/mc --insecure mb admin/cockroachdb >$MINIOLOGFOLDER/mc4.out 2>&1  


