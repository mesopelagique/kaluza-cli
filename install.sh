#!/bin/sh

TMP="${TMPDIR}"
if [ "x$TMP" = "x" ]; then
  TMP="/tmp/"
fi
TMP="${TMP}kaluza.$$"
rm -rf "$TMP" || true
mkdir "$TMP"
if [ $? -ne 0 ]; then
  echo "failed to mkdir $TMP" >&2
  exit 1
fi

cd $TMP

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  archiveName=kaluza.tar.gz
elif [[ "$OSTYPE" == "darwin"* ]]; then  # Mac OSX
  archiveName=kaluza.zip
else
  echo "Unknown os type $OSTYPE"
  archiveName=kaluza.tar.gz
fi

archive=$TMP/$archiveName
curl -sL https://github.com/mesopelagique/kaluza-cli/releases/latest/download/$archiveName -o $archive

unzip -q $archive -d $TMP/

binary=$TMP/.build/release/kaluza 

dst="/usr/local/bin"
echo "Install into $dst/kaluza"
sudo rm -f $dst/kaluza
sudo cp $binary $dst/

rm -rf "$TMP"
