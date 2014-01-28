# returns 0 if $1 has a value, 
# if a second param is used it return 0 if $! == $2
function verifyarg {
  # if we have a $2 check that the $1 equals it
  local ARG=$1
  local EXPECT=$2
  if [ "X${EXPECT}" == "X" ]; then
    # assert that it just has a value
    [ "X${ARG}" != "X" ]
    return $?
  else
    # check arg == expect
    [ "X${ARG}" == "X${EXPECT}" ]
    return $?
  fi
}

function verifyexecutable {
  # test that we have the tools installed
  if which $1 >/dev/null ; then
    return 0
  else
    return 1
  fi
}

function verifytools {
  # test that we have the tools installed
  verifyexecutable ec2-describe-instances
  return $?
}

function message {
  local DO_DEBUG=
  local MESSAGE=
  while [ "$#" -ne 0 ]; do
    case $1 in
      -d | --debug )      DO_DEBUG="true"
                          shift
                          ;;
      * )                 MESSAGE="${MESSAGE}${1}"
                          shift
                          ;;
    esac
  done
  if ! verifyarg "${DO_DEBUG}"; then
    echo "$MESSAGE"
  else
    echo "$MESSAGE" >&2
  fi
}

function error {
  local MESSAGE="$1"
  local -i ERRCODE=1
  if verifyarg "$2"; then
    ERRCODE=$2
  fi
  message -d "$MESSAGE"
  exit $ERRCODE
}

function testtools {
  if ! verifytools; then
    error "Sorry cant find AWS tools like ec2-describe-instance"   
  fi
}

function testsettings {
  local SETTINGS=$1
  verifyarg "$SETTINGS" || error "jjjjjj filename not supplied to testsettings"
  for PROP in $(cat $SETTINGS)
  do
    IFS='=' read -ra P <<<$(echo $PROP);
    local KVS=(${P[@]})
    verifyarg ${KVS[1]} || error "in $SETTINGS ${KVS[0]} has no value"
  done

  verifyarg $REGION || error "REGION is not set"
  verifyarg $ZONE || error "ZONE is not set"
  verifyarg $KEY || error "KEY is not set"
  verifyarg $GROUP || error "GROUP is not set"
  verifyarg $SERVERNAME || error "SERVERNAME is not set"
  verifyarg $VOLNAME || error "VOLNAME is not set"
  verifyarg $VOLDEV || error "VOLDEV is not set"
  verifyarg $VOLSIZE || error "VOLSIZE is not set"
  verifyarg $INSTANCE_TYPE || error "INSTANCE_TYPE is not set"
  verifyarg $AMI || error "AMI is not set"
  return 0
}


##########################################
#         AWS funcs                      #
##########################################
#############################################################
# Thing descriptions                                     #
#############################################################
# usage: describe_thing_by_tag $1 $2 $3 $4                  #
# $1 = <INSTANCE|VOLUME|??>                                 #
# $1 = OUTPUT section                                       #
# $2 = <TAGVALUE>                                           #
# $3 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_thing_by_tag {
  local THING=$1
  local OUTPUT=$2
  local TAG=$3
  local COLUMN=$4
  if verifyarg $THING && verifyarg $TAG && verifyarg OUTPUT && verifyarg COLUMN; then
    case "$THING" in
      "INSTANCE" ) 
         local INFO=`ec2-describe-instances -F tag-value=${TAG} --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       "VOLUME" )
         local INFO=`ec2-describe-volumes -F tag-value=${TAG} --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       "GROUP" )
         local INFO=`ec2-describe-group -F tag-value=${TAG} --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       * )
         error "Oops: describe_thing_by_tag: unknown THING=$THING"
         ;;
    esac
    message "$INFO"
  else
    error "Oops: describe_thing_by_tag: THING=$THING OUTPUT=$OUTPUT TAG=$TAG COLUMN=$COLUMN"
  fi
}

#############################################################
# usage: describe_thing_by_id $1 $2 $3 $4                  #
# $1 = <INSTANCE|VOLUME|??>                                 #
# $2 = OUTPUT section                                       #
# $3 = <ID>                                           #
# $4 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_thing_by_id {
  local THING=$1
  local OUTPUT=$2
  local ID=$3
  local COLUMN=$4
  if verifyarg $THING && verifyarg $ID && verifyarg OUTPUT && verifyarg COLUMN; then
    case "$THING" in
      "INSTANCE" ) 
         local INFO=`ec2-describe-instances $ID --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       "VOLUME" )
         # echo "ec2-describe-volumes $ID --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'"
         local INFO=`ec2-describe-volumes $ID --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       "GROUP" )
         local INFO=`ec2-describe-group $ID --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       * )
         error "Oops: describe_thing_by_id: unknown THING=$THING"
         ;;
    esac
    message "$INFO"
  else
    error "Oops: describe_thing_by_id: THING=$THING OUTPUT=$OUTPUT ID=$ID COLUMN=$COLUMN"
  fi
}



#############################################################
#############################################################
# Instance descriptions                                     #
#############################################################
# usage: describe_instance_by_tag $1 $2 $3                   #
# $1 = <RESERVATION|INSTANCE|BLOCKDEVICE|NIC|NICATTACHMENT> #
# $2 = <TAGVALUE>                                           #
# $3 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_instance_by_tag {
  describe_thing_by_tag "INSTANCE" "$1" "$2" "$3"
}

#############################################################
# usage: describe_instance_by_tag $1 $2 $3                   #
# $1 = <RESERVATION|INSTANCE|BLOCKDEVICE|NIC|NICATTACHMENT> #
# $2 = <ID_Value>                                           #
# $3 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_instance_by_id {
  describe_thing_by_id "INSTANCE" "$1" "$2" "$3"
}

###
# Get the Instance DNS addresses via id
# usage: find_instance_dns_by_id <ID>
function desc_instance_dns_by_id {
  describe_instance_by_id "INSTANCE" $1 4
}

# Get the instance ID via a id value
# usage: desc_instance_id_by_id <Tag>
function desc_instance_id_by_id {
  describe_instance_by_id "INSTANCE" $1 2
}

# Get the instance AMI_ID via id
# usage: desc_instance_ami_by_id <id>
function desc_instance_ami_by_id {
  describe_instance_by_id "INSTANCE" $1 3
}

function desc_instance_status_by_id {
  describe_instance_by_id "INSTANCE" $1 6
}

function desc_instance_blockdevice_name_by_id {
  describe_instance_by_id "BLOCKDEVICE" $1 2
}

function desc_instance_blockdevice_volid_by_id {
  describe_instance_by_id "BLOCKDEVICE" $1 3
}

###
# Get the Instance DNS addresses via a tag name
# usage: find_instance_dns_by_tag <Tag>
function desc_instance_dns_by_tag {
  describe_instance_by_tag "INSTANCE" $1 4
}

# Get the instance ID via a tag value
# usage: desc_instance_id_by_tag <Tag>
function desc_instance_id_by_tag {
  describe_instance_by_tag "INSTANCE" $1 2
}

# Get the instance AMI_ID via a tag value
# usage: desc_instance_ami_by_tag <Tag>
function desc_instance_ami_by_tag {
  describe_instance_by_tag "INSTANCE" $1 3
}

function desc_instance_status_by_tag {
  describe_instance_by_tag "INSTANCE" $1 6
}

function desc_instance_blockdevice_name_by_tag {
  describe_instance_by_tag "BLOCKDEVICE" $1 2
}

function desc_instance_blockdevice_volid_by_tag {
  describe_instance_by_tag "BLOCKDEVICE" $1 3
}

#############################################################
# Volume descriptions                                       #
#############################################################
# usage: describe_volume_by_id $1 $2 $3                     #
# $1 = <VOLUME|ATTACHMENT|TAG>                              #
# $2 = <id>                                                 #
# $3 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_volume_by_id {
  describe_thing_by_id "VOLUME" "$1" "$2" "$3"
}


function desc_volume_id_by_id {
  describe_volume_by_id "VOLUME" $1 2
}

function desc_volume_size_by_id {
  describe_volume_by_id "VOLUME" $1 3
}

function desc_volume_status_by_id {
  describe_volume_by_id "VOLUME" $1 6
}

function describe_volume_attach_status {
  local VOLUMEID=$1; shift;
  local INSTANCEID=$1; shift;
  verifyarg $VOLUMEID && verifyarg $INSTANCEID || error "Error:describe_volume_attach_status: VOLUMEID=$VOLUMEID INSTANCEID=$INSTANCEID" 
  describe_volume_by_id "ATTACHMENT.*${INSTANCEID}" ${VOLUMEID} 5
}


#############################################################
# Volume descriptions                                       #
#############################################################
# usage: describe_volumes_by_tag $1 $2 $3                    #
# $1 = <VOLUME|ATTACHMENT|TAG>                              #
# $2 = <TAGVALUE>                                           #
# $3 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_volumes_by_tag {
  describe_thing_by_tag "VOLUME" "$1" "$2" "$3"
}

function desc_volume_id_by_tag {
  describe_volumes_by_tag "VOLUME" $1 2
}

function desc_volume_size_by_tag {
  describe_volumes_by_tag "VOLUME" $1 3
}

function desc_volume_status_by_tag {
  describe_volumes_by_tag "VOLUME" $1 6
}

#############################################################
# group descriptions                                     #
#############################################################
# usage: describe_instance_by_tag $1 $2 $3                   #
# $1 = <GROUP|PERMISSION> #
# $2 = <TAGVALUE>                                           #
# $3 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_group_by_tag {
  describe_thing_by_tag "GROUP" "$1" "$2" "$3"
}

#############################################################
# usage: describe_instance_by_id $1 $2 $3                   #
# $1 = <RESERVATION|INSTANCE|BLOCKDEVICE|NIC|NICATTACHMENT> #
# $2 = <ID_Value>                                           #
# $3 = <OUTPUT_COL_NUM>                                     #
#############################################################
function describe_group_by_id {
  describe_thing_by_id "GROUP" "$1" "$2" "$3"
}


function desc_group_id_by_tag {
  describe_volumes_by_tag "GROUP" $1 2
}

function desc_group_name_by_tag {
  describe_volumes_by_tag "GROUP" $1 4
}

function desc_group_desc_by_tag {
  describe_volumes_by_tag "GROUP" $1 5
}



###########################################################
# Create things                                           #
###########################################################
##
# Create Volume
# VOLUME=`ec2-create-volume -s 50 --region ${REGION} -z ${ZONE} | awk '/VOLUME/ {print $2}'`
#############################################################
# create volume and tag it. return the volID
function create_volume {
  local TAG=$1; shift
  local SIZE=$1; shift
  verifyarg $TAG && verifyarg $SIZE || error "Error:create_volume: TAG=$TAG SIZE=$SIZE"
  local VOLUME=`ec2-create-volume --size ${SIZE} --region ${REGION} -z ${ZONE} | awk '/VOLUME/ {print $2}'`
  local TAGDETAILS=`ec2-create-tags ${VOLUME} -t Name=${TAG} --region ${REGION}`
  message $VOLUME
}
function create_snapshot {
  local TAG=$1; shift
  local FROM=$1; shift
  local DESC=$1; shift
  verifyarg "$TAG" && verifyarg "$FROM" && verifyarg "$DESC" || error "Error:create_snapshot: TAG=$TAG FROM=$FROM DESC=\"$DESC\""
  TAG="-${TAG}"
  local FROMIDs=`desc_volume_id_by_tag $FROM`
  for F in $FROMIDs; do 
    local SNAP=`ec2-create-snapshot --region ${REGION} -d "${DESC}" "${F}" | awk '/SNAPSHOT/ {print $2}'`
    local TAGDETAILS=`ec2-create-tags ${SNAP} -t Name=snapshot-${F}${TAG} --region ${REGION}`
    message "$SNAP" 
  done
}
function create_sized_volume {
  local TAG=$1
  local SIZE=$2
  verifyarg $TAG && verifyarg $SIZE || error "Error:create_50G_volume: TAG=$TAG SIZE=$SIZE"
  create_volume $TAG $SIZE
}
function create_50G_volume {
  create_sized_volume $1 50
}
function delete_volume_by_id {
  local ID=$1
  verifyarg $ID  || error "Error:delete_volume_by_id: No ID supplied"
  local THEID=$(ec2-delete-volume --region ${REGION} $ID | awk '/VOLUME/ {print $2}')
  message $THEID
}
function delete_volume_by_tag {
  local TAG=$1
  verifyarg $TAG || error "Error:delete_volumes_by_tag: No TAG supplied"
  local IDs=`desc_volume_id_by_tag $TAG`
  for id in $IDs; do
    local i=`delete_volume_by_id $id`
    message -d "delted volume $i"
  done
}

#############################
#     Attach volumes        #
#############################
function attach_volume_to_instance_by_ids {
  local VOLUME=$1; shift
  local INSTANCE=$2; shift
  local DEVICE=$3; shift
  verifyarg $VOLUME && verifyarg $INSTANCE && verifyarg $DEVICE || error "Error:attach_volume_to_instance_by_ids: VOLUME=$VOLUME INSTANCE=$INSTANCE DEVICE=$DEVICE"
  ec2-attache-volume "${VOLUME}" -i "${INSTANCE}" -d "${DEVICE}" --region ${REGION}
}

function detach_volume_to_instance_by_ids {
  local VOLUME=$1; shift
  local INSTANCE=$2; shift
  local DEVICE=$3; shift
  verifyarg $VOLUME && verifyarg $INSTANCE && verifyarg $DEVICE || error "Error:detach_volume_to_instance_by_ids: VOLUME=$VOLUME INSTANCE=$INSTANCE DEVICE=$DEVICE"
  ec2-detache-volume "${VOLUME}" -i "${INSTANCE}" -d "${DEVICE}" --region ${REGION}
}

function start_instance {
  local AMI=$1; shift;
  local INSTANCE_TYPE=$1; shift;
  local GROUP=$1; shift;
  verifyarg $AMI && verifyarg $GROUP || error "Error:start_instance: AMI=$AMI GROUP=$GROUP"
  local INSTANCE=`ec2-run-instances $AMI -n 1 -k $KEY --instance-type $INSTANCE_TYPE -g $GROUP --region $REGION -z $ZONE | grep INSTANCE | awk '{print $2}'` 
  echo $INSTANCE
}

function create_group_basic {
  local NAME=$1; shift;
  local DESC=$1; shift;
  verifyarg $NAME && verifyarg $DESC || error "Error:create_group: NAME=$NAME DESC=$DESC"

   ec2-create-group $NAME -d "Security group for git server" --region $REGION
   ec2-authorize-group $NAME -P tcp -p 80 --region $REGION
   ec2-authorize-group $NAME -P tcp -p 443 --region $REGION
   ec2-authorize-group $NAME -P tcp -p 22 --region $REGION
   ec2-authorize-group $NAME -P tcp -p 9418 --region $REGION
}



