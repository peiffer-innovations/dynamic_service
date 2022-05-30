#/bin/bash
set -e

for dir in ./*/
do
  dir=${dir%*/}
  cd $dir
  pwd
  # if test -d ".git"; then
    # git pull
  # fi

  if test -f "get_all.sh"; then
    sh get_all.sh
  fi

  if test -d "bin"; then
    pre-commit install
    dart pub get
  elif test -f "pubspec.yaml"; then
    pre-commit install
    flutter packages upgrade
  fi

  if test -d "example"; then
    cd example
    flutter packages upgrade
    cd ..
  fi
  cd ..
done
