#!/bin/bash
. settings.conf

INSTANCE=`ec2-describe-instances -F tag-value=${NAME} --region $REGION | awk '/INSTANCE/ {print $2}'`

echo INSTANCE=$INSTANCE
VOLUME=`ec2-create-volume -s 50 --region ${REGION} -z ${ZONE} | awk '/VOLUME/ {print $2}'`
echo "Volumeid is : $VOLUME"
ec2-create-tags ${VOLUME} -t Name=${VOLNAME} --region ${REGION}

