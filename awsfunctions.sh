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
  verifyarg $NAME || error "NAME is not set"
  verifyarg $VOLNAME || error "VOLNAME is not set"
  verifyarg $VOLDEV || error "VOLDEV is not set"
  return 0
}


##########################################
#         AWS funcs                      #
##########################################
#############################################################
# Thing descriptions                                     #
#############################################################
# usage: describe-thing-by-tag $1 $2 $3 $4                  #
# $1 = <INSTANCE|VOLUME|??>                                 #
# $1 = OUTPUT section                                       #
# $2 = <TAGVALUE>                                           #
# $3 = <OUTPUT-COL-NUM>                                     #
#############################################################
function describe-thing-by-tag {
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
 #             echo "ec2-describe-volumes -F tag-value=${TAG} --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'"
         local INFO=`ec2-describe-volumes -F tag-value=${TAG} --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       * )
         error "Oops: describe-thing-by-tag: unknown THING=$THING"
         ;;
    esac
    message "$INFO"
  else
    error "Oops: describe-thing-by-tag: THING=$THING OUTPUT=$OUTPUT TAG=$TAG COLUMN=$COLUMN"
  fi
}

#############################################################
# usage: describe-thing-by-id $1 $2 $3 $4                  #
# $1 = <INSTANCE|VOLUME|??>                                 #
# $2 = OUTPUT section                                       #
# $3 = <ID>                                           #
# $4 = <OUTPUT-COL-NUM>                                     #
#############################################################
function describe-thing-by-id {
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
  #       echo "ec2-describe-volumes $ID --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'" >&2
         local INFO=`ec2-describe-volumes $ID --region $REGION | awk '/'${OUTPUT}'/ {print $'$COLUMN'}'`
         ;;
       * )
         error "Oops: describe-thing-by-id: unknown THING=$THING"
         ;;
    esac
    message "$INFO"
  else
    error "Oops: describe-thing-by-id: THING=$THING OUTPUT=$OUTPUT ID=$ID COLUMN=$COLUMN"
  fi
}



#############################################################
#############################################################
# Instance descriptions                                     #
#############################################################
# usage: describe-instance-by-tag $1 $2 $3                   #
# $1 = <RESERVATION|INSTANCE|BLOCKDEVICE|NIC|NICATTACHMENT> #
# $2 = <TAGVALUE>                                           #
# $3 = <OUTPUT-COL-NUM>                                     #
#############################################################
function describe-instance-by-tag {
  describe-thing-by-tag "INSTANCE" "$1" "$2" "$3"
}

#############################################################
# usage: describe-instance-by-tag $1 $2 $3                   #
# $1 = <RESERVATION|INSTANCE|BLOCKDEVICE|NIC|NICATTACHMENT> #
# $2 = <ID-Value>                                           #
# $3 = <OUTPUT-COL-NUM>                                     #
#############################################################
function describe-instance-by-id {
  describe-thing-by-id "INSTANCE" "$1" "$2" "$3"
}

###
# Get the Instance DNS addresses via id
# usage: find-instance-dns-by-id <ID>
function desc-instance-dns-by-id {
  describe-instance-by-id "INSTANCE" $1 4
}

# Get the instance ID via a id value
# usage: desc-instance-id-by-id <Tag>
function desc-instance-id-by-id {
  describe-instance-by-id "INSTANCE" $1 2
}

# Get the instance AMI-ID via id
# usage: desc-instance-ami-by-id <id>
function desc-instance-ami-by-id {
  describe-instance-by-id "INSTANCE" $1 3
}

function desc-instance-status-by-id {
  describe-instance-by-id "INSTANCE" $1 6
}

function desc-instance-blockdevice-name-by-id {
  describe-instance-by-id "BLOCKDEVICE" $1 2
}

function desc-instance-blockdevice-volid-by-id {
  describe-instance-by-id "BLOCKDEVICE" $1 3
}

###
# Get the Instance DNS addresses via a tag name
# usage: find-instance-dns-by-tag <Tag>
function desc-instance-dns-by-tag {
  describe-instance-by-tag "INSTANCE" $1 4
}

# Get the instance ID via a tag value
# usage: desc-instance-id-by-tag <Tag>
function desc-instance-id-by-tag {
  describe-instance-by-tag "INSTANCE" $1 2
}

# Get the instance AMI-ID via a tag value
# usage: desc-instance-ami-by-tag <Tag>
function desc-instance-ami-by-tag {
  describe-instance-by-tag "INSTANCE" $1 3
}

function desc-instance-status-by-tag {
  describe-instance-by-tag "INSTANCE" $1 6
}

function desc-instance-blockdevice-name-by-tag {
  describe-instance-by-tag "BLOCKDEVICE" $1 2
}

function desc-instance-blockdevice-volid-by-tag {
  describe-instance-by-tag "BLOCKDEVICE" $1 3
}

#############################################################
# Volume descriptions                                       #
#############################################################
# usage: describe-volume-by-id $1 $2 $3                     #
# $1 = <VOLUME|ATTACHMENT|TAG>                              #
# $2 = <id>                                                 #
# $3 = <OUTPUT-COL-NUM>                                     #
#############################################################
function describe-volume-by-id {
  describe-thing-by-id "VOLUME" "$1" "$2" "$3"
}


function desc-volume-id-by-id {
  describe-volume-by-id "VOLUME" $1 2
}

function desc-volume-size-by-id {
  describe-volume-by-id "VOLUME" $1 3
}

function desc-volume-status-by-id {
  describe-volume-by-id "VOLUME" $1 6
}


#############################################################
# Volume descriptions                                       #
#############################################################
# usage: describe-volumes-by-tag $1 $2 $3                    #
# $1 = <VOLUME|ATTACHMENT|TAG>                              #
# $2 = <TAGVALUE>                                           #
# $3 = <OUTPUT-COL-NUM>                                     #
#############################################################
function describe-volumes-by-tag {
  describe-thing-by-tag "VOLUME" "$1" "$2" "$3"
}

function desc-volume-id-by-tag {
  describe-volumes-by-tag "VOLUME" $1 2
}

function desc-volume-size-by-tag {
  describe-volumes-by-tag "VOLUME" $1 3
}

function desc-volume-status-by-tag {
  describe-volumes-by-tag "VOLUME" $1 6
}

###########################################################
# Create things                                           #
###########################################################
##
# Create Volume
# VOLUME=`ec2-create-volume -s 50 --region ${REGION} -z ${ZONE} | awk '/VOLUME/ {print $2}'`
#############################################################
# create volume and tag it. return the volID
function create-volume {
  local TAG=$1; shift
  local SIZE=$1; shift
  verifyarg $TAG && verifyarg $SIZE || error "Error:create-volume: TAG=$TAG SIZE=$SIZE"
  local VOLUME=`ec2-create-volume --size ${SIZE} --region ${REGION} -z ${ZONE} | awk '/VOLUME/ {print $2}'`
  local TAGDETAILS=`ec2-create-tags ${VOLUME} -t Name=${TAG} --region ${REGION}`
  message $VOLUME
}
function create-snapshot {
  local TAG=$1; shift
  local FROM=$1; shift
  local DESC=$1; shift
  verifyarg "$TAG" && verifyarg "$FROM" && verifyarg "$DESC" || error "Error:create-snapshot: TAG=$TAG FROM=$FROM DESC=\"$DESC\""
  TAG="-${TAG}"
  local FROMIDs=`desc-volume-id-by-tag $FROM`
  for F in $FROMIDs; do 
    local SNAP=`ec2-create-snapshot --region ${REGION} -d "${DESC}" "${F}" | awk '/SNAPSHOT/ {print $2}'`
    local TAGDETAILS=`ec2-create-tags ${SNAP} -t Name=snapshot-${F}${TAG} --region ${REGION}`
    message "$SNAP" 
  done
}
function create-sized-volume {
  local TAG=$1
  local SIZE=$2
  verifyarg $TAG && verifyarg $SIZE || error "Error:create-50G-volume: TAG=$TAG SIZE=$SIZE"
  create-volume $TAG $SIZE
}
function create-50G-volume {
  create-sized-volume $1 50
}
function delete-volume-by-id {
  local ID=$1
  verifyarg $ID  || error "Error:delete-volume-by-id: No ID supplied"
  local THEID=$(ec2-delete-volume --region ${REGION} $ID | awk '/VOLUME/ {print $2}')
  message $THEID
}
function delete-volume-by-tag {
  local TAG=$1
  verifyarg $TAG || error "Error:delete-volumes-by-tag: No TAG supplied"
  local IDs=`desc-volume-id-by-tag $TAG`
  for id in $IDs; do
    local i=`delete-volume-by-id $id`
    message -d "delted volume $i"
  done
}


