#! /bin/bash

DIR=$(dirname $0)

function print_usage {
  echo -e "Usage: $0 <MajorVersion> <FullVersion>\n"
  echo -e "Example: $0 2.0 2.0.123456"
  echo -e "Example: $0 3.0 3.1.1"
}

if [ "$1" != "2.0" ] && [ "$1" != "3" ] && [ "$1" != "4" ]; then
  echo -e "MajorVersion must be 2.0, 3., or 4. Got '$1'\n"
  print_usage
  exit 1
fi

if [ -z "$2" ]; then
  echo -e "FullVersion is required.\n"
  print_usage
  exit 1
fi

if [ "$1" == "3" ]; then
   find $DIR/3.0 -name "*Dockerfile" -exec sed -i "s/\bHOST_VERSION=$1\..*/HOST_VERSION=$2/g" "$0" {} \;
else 
   find $DIR/$1 -name "*Dockerfile" -exec sed -i "s/\bHOST_VERSION=$1\..*/HOST_VERSION=$2/g" "$0" {} \;
fi