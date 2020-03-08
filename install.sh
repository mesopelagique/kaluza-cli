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

archive=$TMP/kaluza.zip
curl -sL https://github.com/mesopelagique/kaluza-cli/releases/latest/download/kaluza.zip -o $archive

unzip -q $archive -d $TMP/

binary=$TMP/.build/release/kaluza 

dst="/usr/local/bin"
echo "Install into $dst/kaluza"
rm -f $dst/kaluza
cp $binary $dst/

rm -rf "$TMP"