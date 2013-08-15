#!/bin/bash
. settings.conf

INSTANCE=`ec2-describe-instances -F tag-value=${NAME} --region $REGION | awk '/INSTANCE/ {print $2}'`

echo INSTANCE=$INSTANCE
VOLUME=`ec2-describe-volumes -F tag-value=${VOLNAME} --region ${REGION} | awk '/VOLUME/ {print $2}'`
echo "Volumeid is : $VOLUME"

ec2-attach-volume ${VOLUME} -i ${INSTANCE} -d ${VOLDEV} --region ${REGION}
