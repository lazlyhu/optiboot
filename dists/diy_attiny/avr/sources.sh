#!/bin/bash
#
# This file specifies external files/folders from github locations
#  which are used in this distribution and should be updated
#  as necessary to incorporate into the hardware definition.
#
# The repos mentioned are checked out into 
#     {dirpath_to_makedist.sh}/.sources.tmp/REPO_NAME
#  and you can edit in there if you want while developing.
# 

function main
{
  # Ensure we have certain directories
  [ -d cores ]    || mkdir cores
  [ -d variants ] || mkdir variants
  
  # github https://github.com/damellis/attiny/tree/master/attiny/variants/tiny8    variants/tiny8
  # github https://github.com/damellis/attiny/tree/master/attiny/variants/tiny14   variants/tiny14
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/cores/tiny           cores/tiny
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tinyX5      variants/tinyX5
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tinyX4_Arduino_Numbering      variants/tinyX4
  #github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tinyX4      variants/tinyX4
  
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tiny13      variants/tiny13
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tiny5_10    variants/tiny5_10
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tiny4_9     variants/tiny4_9
  
  # Libraries, these include examples for ATTinyCore chips
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/libraries      libraries
  
  # We need to grab most of the platform.txt information from the ATTinyCore 
  #  except we want to use our own avrdude stuff
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/platform.txt         platform.tmp.txt  
  cat >platform.txt <<EOF
###############################################################################
#
# This platform.txt has been created from the combination of 
# https://github.com/sleemanj/ATTinyCore/tree/master/avr/platform.txt
# and the platform.local.txt in this folder
#
# DO NOT EDIT THIS FILE
# -----------------------------------------------------------------------------
# This file is created automatically by \`sources.sh\` when the diy_attiny
# distribution is updated with \`makdedist.sh\`
#
###############################################################################

name=DIY ATtiny
version=${VERSION}
EOF
  cat platform.tmp.txt | grep -v "name=" | grep -v "version=" >>platform.txt
  
  # Remove any configs we have made in platform.local.txt from the platform.txt
  # NB: platform.local.txt is actually a filename that arduino also looks for, but
  #     there is no documentation on what exactly can be 'overridden' in it, is it 
  #     just certain things, or everything, so that's why we are manually doing this
  #     that way we KNOW it works
  
  local KNOWNKEYS="$(cat platform.local.txt | grep -P "^[a-z]" | sed -r "s/=.*//" )"
  for key in $KNOWNKEYS
  do
    mv platform.txt platform.tmp.txt    
    grep -vF "$key=" platform.tmp.txt >platform.txt
  done
  
  rm platform.tmp.txt    
  echo >>platform.txt
  cat platform.local.txt | grep -v "#" >>platform.txt
  
  
  # Because of:
  #   https://github.com/arduino/Arduino/issues/4619
  # it is best that we duplicate programmers.txt and make a unique name for each one in it    
  cat >programmers.txt <<EOF
###############################################################################
#
# This programmers.txt is copied from programmers.local.txt in this folder
#
# DO NOT EDIT THIS FILE
# -----------------------------------------------------------------------------
# This file is created automatically by \`sources.sh\` when the diy_attiny
# distribution is updated with \`makdedist.sh\`
#
###############################################################################
EOF

cat >avrdude.conf <<EOF
###############################################################################
#
# This avrdude.conf is copied from avrdude.local.conf in this folder
#
# DO NOT EDIT THIS FILE
# -----------------------------------------------------------------------------
# This file is created automatically by \`sources.sh\` when the diy_attiny
# distribution is updated with \`makdedist.sh\`
#
###############################################################################
EOF

  if grep -F "#define" avrdude.local.conf >/dev/null
  then  
    cat avrdude.local.conf >>avrdude.conf
    wget https://raw.githubusercontent.com/arduino/Arduino/master/hardware/arduino/avr/programmers.txt -O programmers.tmp.txt
    cat programmers.tmp.txt | sed -r 's/\.name=(.*)/.name=DIY ATmega: \1/' >>programmers.txt  
    echo >>programmers.txt
    cat programmers.local.txt | grep -v "#" >>programmers.txt
    rm  programmers.tmp.txt
  else
    # Not using a custom avrdude.conf        
    cat programmers.local.txt | grep -v "#" >>programmers.txt
    
    # If we have our own programmers we MUST have our own 
    # avrdude.conf, so copy it in place from arduino.  This whole configuration system is an inconsistent mess.
    # The local file will include some other since it isnt an avrdude.conf itself   
    cat $(grep -F "#include" avrdude.local.conf | sed -r 's/.*"(.*)".*/\1/') >>avrdude.conf
    
  fi
  
}

function github
{
  local TMP_DIR=$(dirname $(realpath $0))/../../../.sources.tmp/  
  local OUT_DIR=$(dirname $(realpath $0))
  if [ ! -d $TMP_DIR ]
  then
    mkdir $TMP_DIR || exit 1
  fi
  
  local GIT="$(echo $1 | sed 's/\/tree.*/.git/')"
  local GITNAME="$(echo $GIT | sed 's/.*\///' | sed 's/\.git//' )"
  local BRANCH="$(echo $1 | sed 's/.*tree\///' | sed 's/\/.*//')"
  local FILES="$(echo $1 | sed "s/..*\/tree\/$BRANCH\///")"
  pushd $TMP_DIR
    if [ ! -d $GITNAME ]
    then
      git clone $GIT      
    fi
    pushd $GITNAME
      git checkout $BRANCH      
    popd
    rm -rf $OUT_DIR/$2
    cp -rP $GITNAME/$FILES $OUT_DIR/$2
  popd
}

main "$@"