#!/bin/bash
# Builds a new release of geotoad

# For Windows build, we require a Ruby installation including the "Ocra" gem

if [ ! -f VERSION ];  then
  echo "VERSION not found"
  exit 2
fi
base_dir=`pwd`
src_dir="/tmp/namebench-$$"
trap "/bin/rm -Rf $src_dir/ $base_dir/dist/*/; exit 0" 0 1 2 3 6 9 15
svn checkout http://geotoad.googlecode.com/svn/trunk/ $src_dir
cd $src_dir
svn log >ChangeLog.txt

VERSION=`cat VERSION`
DISTNAME="geotoad-$VERSION"
DEST="${base_dir}/dist"
GENERIC_DIR=$DEST/$DISTNAME
GENERIC_PKG="${GENERIC_DIR}.zip"
GENERIC_TGZ="${GENERIC_DIR}.tar.gz"

MAC_DIR="$DEST/GeoToad for Mac"
MAC_PKG="$DEST/${DISTNAME}_MacOSX.dmg"

WIN_DIR=$DEST/${DISTNAME}_for_Windows
WIN_PKG="$DEST/${DISTNAME}_Windows.zip"

echo "Erasing old distributions."
rm -Rf "$DEST"

echo "Creating $GENERIC_DIR"
mkdir -p "$GENERIC_DIR"
rsync -a --exclude ".svn/" . $GENERIC_DIR

sed s/"%VERSION%"/"$VERSION"/g lib/version.rb > $GENERIC_DIR/lib/version.rb
sed s/"%VERSION%"/"$VERSION"/g README.txt > $GENERIC_DIR/README.txt
sed s/"%VERSION%"/"$VERSION"/g FAQ.txt > $GENERIC_DIR/FAQ.txt
chmod 755 $GENERIC_DIR/*.rb
rm $GENERIC_DIR/VERSION $GENERIC_DIR/tools/countryrip.rb $GENERIC_DIR/tools/*.sh $GENERIC_DIR/data/*.gz

# create PDF version of manual page
groff -Tps -mman $GENERIC_DIR/geotoad.1 | ps2pdf - $GENERIC_DIR/geotoad.pdf

# Make a duplicate of it for Macs before we nuke the .command file
cp -Rp $GENERIC_DIR "$MAC_DIR"
rm $GENERIC_DIR/*.command
ln -s geotoad.rb geotoad
cd "$DEST"
zip -r "$GENERIC_PKG" "$DISTNAME"
tar zcf "$GENERIC_TGZ" "$DISTNAME"

# Mac OS X
if [ -d "/Applications" ]; then
  echo "Creating $MAC_DIR"
  rm "$MAC_DIR/geotoad"
  rm "$MAC_DIR/geotoad.1"
  rm -Rf "$MAC_DIR/debian"
  cd "$MAC_DIR"
  sips -i data/bufos-icon.icns && DeRez -only icns data/bufos-icon.icns > data/icns.rsrc
  Rez -append data/icns.rsrc -o "GeoToad for Mac.command"
  SetFile -a E "GeoToad for Mac.command"
  SetFile -a C "GeoToad for Mac.command"
  rm data/icns.rsrc
  echo "Creating $MAC_PKG"
  hdiutil create -srcfolder "$MAC_DIR" "$MAC_PKG"
  echo "done with $MAC_PKG"
else
  echo "Skipping Mac OS X release"
fi

# Windows
if [ ! -x "/usr/local/bin/flip" -o ! -x "/usr/bin/flip" ]; then
  echo "Creating $WIN_DIR"
  cp -Rp "$GENERIC_DIR" "$WIN_DIR"
  rm "$WIN_DIR/geotoad.1"
  rm -Rf "$WIN_DIR/debian"
  cd "$WIN_DIR"
  mkdir compile
  mv *.rb lib interface data compile/
  flip -mvb *.txt
  perl -pi -e 's/([\s])geotoad\.rb/$1geotoad/g' README.txt

  cat <<EOF >ocrabuild.bat
@echo off
z:
cd compile
call ocra --console geotoad.rb
rem for some yet unknown reason, this part isn't reached
dir
cd ..
pause
EOF

  /bin/echo "In Windows Z:\\dist\\${DISTNAME}_for_Windows, run:"
  echo ""
  echo "ocrabuild.bat"
  echo ""
  read -p "Then press ENTER: " ENTER
  cd $WIN_DIR
  rm -f ocrabuild.bat
  mv compile/geotoad.exe compile/data ./
  ls

  if [ ! -f geotoad.exe ]; then
    echo "geotoad.exe not found"
  else
    rm -Rf "$WIN_DIR/compile"
    zip -r "$WIN_PKG" *
    cat <<EOF >geotoad.iss
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
AppName=GeoToad
AppVersion=${VERSION}
DefaultDirName={pf}\GeoToad
DefaultGroupName=GeoToad
UninstallDisplayIcon={app}\geotoad.exe

[Files]
Source: "geotoad.exe";               DestDir: "{app}"
Source: "contrib\Delorme_Icons\*.*"; DestDir: "{app}\contrib\Delorme_Icons"
Source: "data\*.*";                  DestDir: "{app}\data"
Source: "tools\*.*";                 DestDir: "{app}\tools"
Source: "ChangeLog.txt";             DestDir: "{app}"
Source: "COPYRIGHT.txt";             DestDir: "{app}"
Source: "FAQ.txt";                   DestDir: "{app}"
Source: "TODO.txt";                  DestDir: "{app}"; Flags: skipifsourcedoesntexist
Source: "README.txt";                DestDir: "{app}"; Flags: isreadme
Source: "geotoad.pdf";               DestDir: "{app}"; Flags: skipifsourcedoesntexist

[Icons]
Name: "{group}\GeoToad"; Filename: "{app}\geotoad.exe"
EOF
  cat <<EOF >innobuild.bat
@echo off
z:
cd .
c:\\Programme\\"Inno Setup 5"\\iscc /o.. /f${DISTNAME}_Windows_Installer geotoad.iss
cd ..
dir
pause
EOF
    /bin/echo "In Windows Z:\\dist\\${DISTNAME}_for_Windows, run:"
    echo ""
    echo "innobuild.bat"
    echo ""
    read -p "Then press ENTER: " ENTER
  fi
else
  echo "Skipping Windows Release (no flip found)"
fi
