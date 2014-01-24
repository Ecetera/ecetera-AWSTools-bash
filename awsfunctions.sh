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
  if verifyarg "${DO_DEBUG}"; then
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

function info-by-tag {
  local TAG=$1
  local COLUMN=$2
  if verifyarg $TAG; then
    local INFO=`ec2-describe-instances -F tag-value=${TAG} --region $REGION | awk '/INSTANCE/ {print $'$COLUMN'}'`
    message "$INFO"
  fi
}



# Get the IP addresses via a tag name
# usage: find-ip-by-tag <Tag>
function find-ip-by-tag {
  local TAG=$1
  info-by-tag $TAG 4
}

# Get the instancename via a tag name
# usage: find-instance-by-tag <Tag>
function find-instance-by-tag {
  local TAG=$1
  info-by-tag $TAG 2
}


