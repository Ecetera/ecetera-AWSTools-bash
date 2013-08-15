#!/bin/bash
. settings.conf

IPADDRESS=`ec2-describe-instances -F tag-value=${NAME} --region $REGION | awk '/INSTANCE/ {print $4}'`

echo IPADDRESS = $IPADDRESS
echo "ssh -i ~/.ssh/EceteraTS.pem root@${IPADDRESS}"
#VOLUME=`ec2-describe-volumes -F tag-value=${VOLNAME} --region ${REGION} | awk '/VOLUME/ {print $2}'`

