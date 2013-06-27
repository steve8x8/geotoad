#!/bin/bash
# Builds a new development release of geotoad from SVN trunk
# For Windows build, "Pik" and "Ocra" gems are necessary.
# optional parameters:
# $@: Ruby versions for Pik

# sanity checks
INITIALDIR=`pwd`
if [ ! -f VERSION ];  then
  echo "VERSION not found"
  exit 2
fi
if [ ! -d tools ]; then
  echo "Must start in the main directory by calling tools/makedist"
  exit 3
fi

DEFAULTRUBY=193
SVNPATH=http://geotoad.googlecode.com/svn/trunk/

# checkout SVN to temporary directory
src_dir=/tmp/geotoad-$$
base_dir=`pwd`
DEST=$base_dir/dist

# clean up when done
trap "/bin/rm -Rf $src_dir/ $DEST/*/ $DEST/*.sh; exit 0" 0 1 2 3 6 9 15

# get fresh SVN copy
echo "Checking out SVN from $SVNPATH"
svn checkout --quiet $SVNPATH $src_dir
cd $src_dir
SVNREV=`svn info | sed -n 's~^Revision:\s*~~p'`
echo "SVN revision $SVNREV"
echo "Writing ChangeLog.txt"
svn log -v > ChangeLog.txt

# modify build behaviour
SVN=""
RUBYVERSIONS=${@:-$DEFAULTRUBY}
if [ -n "$SVN" ]; then
  echo "*** Append to version: \"$SVN\". "
fi
read -p "*** Build for Windows Ruby version(s): $RUBYVERSIONS. OK? " x

VERSION=`cat VERSION`$SVN
DISTNAME="geotoad-$VERSION"
DEBNAME="geotoad_$VERSION"
DEBBUILD=1

echo ""
echo "Building $DISTNAME"

if [ -e $DEST ]; then
  echo "Erasing old $DEST"
  rm -Rf $DEST
fi

# generic stuff goes here
GENERIC_DIR="$DEST/$DISTNAME"
#$#GENERIC_PKG="$DEST/$DISTNAME.zip"
GENERIC_TGZ="$DEST/$DISTNAME.tar.gz"

# MacOSX
MAC_DIR="$DEST/GeoToad for Mac"
MAC_PKG="$DEST/${DISTNAME}_MacOSX.dmg"

# Windows
WIN_DIR="$DEST/GeoToad for Windows"
#$#WIN_PKG="$DEST/${DISTNAME}_Windows.zip"
WIN_INS="$DEST/${DISTNAME}_Windows_Installer" #...

#echo "Creating $GENERIC_DIR"
mkdir -p "$GENERIC_DIR"
rsync -a --exclude ".svn/" $src_dir/. $GENERIC_DIR/

# insert version string
sed s/"%VERSION%"/"$VERSION"/g lib/version.rb > $GENERIC_DIR/lib/version.rb
sed s/"%VERSION%"/"$VERSION"/g README.txt > $GENERIC_DIR/README.txt
sed s/"%VERSION%"/"$VERSION"/g FAQ.txt > $GENERIC_DIR/FAQ.txt

cd $GENERIC_DIR
# fix permissions
chmod 755 *.rb
# remove non-distributable stuff
rm VERSION tools/countryrip.rb tools/*.sh data/*.gz
# create PDF version of manual page
groff -Tps -mman geotoad.1 | ps2pdf - geotoad.pdf

# Make a duplicate for Macs before we nuke the .command file
#echo "Creating \"$MAC_DIR\""
cp -Rp $GENERIC_DIR "$MAC_DIR"
rm *.command

cd $DEST
# Source: (ZIP and) TGZ
echo ""
echo "Build source package"
#$#zip -q -r "$GENERIC_PKG" "$DISTNAME"
tar zcf "$GENERIC_TGZ" "$DISTNAME"
echo "Done."

# Mac OS X: DMG
echo ""
echo "Build MacOSX package"
cd "$MAC_DIR"
rm -f geotoad.1
rm -Rf debian
if [ -d "/Applications" ]; then
  # native installation (cannot test this - S)
  export PATH=/Developer/Tools:/Applications/Xcode.app/Contents/Developer/usr/bin:${PATH}
  sips -i data/bufos-icon.icns && DeRez -only icns data/bufos-icon.icns > data/icns.rsrc
  Rez -append data/icns.rsrc -o "GeoToad for Mac.command"
  SetFile -a E "GeoToad for Mac.command"
  SetFile -a C "GeoToad for Mac.command"
  rm data/icns.rsrc
  echo "Creating $MAC_PKG"
  hdiutil create -srcfolder "$MAC_DIR" "$MAC_PKG"
  echo "Done with $MAC_PKG"
else
  # prepare for external building
  echo "Prepare for external MacOSX build"
  cat >../run_mac.sh <<EOF
#!/bin/bash
cd \$(dirname \$0)
export PATH=/Developer/Tools:/Applications/Xcode.app/Contents/Developer/usr/bin:\${PATH}
if [ -d "/Applications" ]; then
  cd "GeoToad for Mac"
  sips -i data/bufos-icon.icns && DeRez -only icns data/bufos-icon.icns > data/icns.rsrc
  Rez -append data/icns.rsrc -o "GeoToad for Mac.command"
  SetFile -a E "GeoToad for Mac.command"
  SetFile -a C "GeoToad for Mac.command"
  rm data/icns.rsrc
  cd ..
  echo "Creating MacOSX package"
  hdiutil create -ov -fs "Case-sensitive HFS+" -srcfolder "GeoToad for Mac" "${DISTNAME}_MacOSX.dmg"
  ls -l "${DISTNAME}_MacOSX.dmg"
  echo "Done with MacOSX package"
fi
EOF
  cd ..
  chmod +x run_mac.sh
  echo "*** Copy \"run_mac.sh\" and \"GeoToad for Mac\" to a MacOSX machine,"
  echo "    run \"./run_mac.sh\","
  echo "    and copy \"${DISTNAME}_MacOSX.dmg\""
  echo "     back to $DEST when done."
  read -p "*** Press ENTER to proceed: " x
fi
if [ -f "$MAC_PKG" ]; then
  echo "Done."
else
  echo "*** MacOSX package not found (yet)!"
fi

# Windows
if [ -x "/usr/local/bin/flip" -o -x "/usr/bin/flip" ]; then
  for RUBYVERSION in $RUBYVERSIONS
  do
    SUFFIX=""
    if [ `echo $RUBYVERSIONS | wc -w` -gt 1 ]; then
      SUFFIX=_Ruby`echo $RUBYVERSION | cut -c1-2`
    fi
    echo ""
    echo "Build Windows package for ruby version $RUBYVERSION ($SUFFIX)"
    # Windows: EXE
#    echo "Creating \"$WIN_DIR\""
    cd $DEST
    rm -Rf "$WIN_DIR"
    cp -Rp "$GENERIC_DIR" "$WIN_DIR"
    cd "$WIN_DIR"
    rm -f geotoad.1
    rm -Rf debian
    mkdir compile
    mv *.rb lib interface data templates compile/
    flip -mb *.txt
    perl -pi -e 's/([\s])geotoad\.rb/$1geotoad/g' README.txt
    # input file for Ocra gem
    cat <<EOF >ocrabuild.bat
@echo on
z:
call pik switch $RUBYVERSION
call pik ls
path
cd compile
call ocra --console geotoad.rb
dir
cd ..
pause
EOF
    /bin/echo "*** In Windows \"Z:\\...\\dist\\GeoToad for Windows\", run:"
    echo "      ocrabuild.bat"
    read -p "*** Press ENTER when done (geotoad.exe exists): " x
    cd "$WIN_DIR"
    rm -f ocrabuild.bat
    # we might need better error handling (back to square one?)
    if [ ! -f compile/geotoad.exe ]; then
      echo "*** Skipping installer build step (geotoad.exe not found)"
    else
      mv compile/geotoad.exe compile/data ./
      rm -Rf "$WIN_DIR"/compile
#$#      # pack into zip
#$#      zip -q -r "$WIN_PKG" *
      # Windows: Installer
      # input files for inno setup
      cat <<EOF >geotoad.iss
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
AppName=GeoToad
AppVersion=$VERSION
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
c:\\Programme\\"Inno Setup 5"\\iscc /o.. /f${DISTNAME}_Windows_Installer$SUFFIX geotoad.iss
cd ..
dir
pause
EOF
      /bin/echo "*** In Windows \"Z:\\...\\dist\\GeoToad for Windows\", run:"
      echo "      innobuild.bat"
      read -p "*** Press ENTER when done (${DISTNAME}_Windows_Installer$SUFFIX.exe exists): " x
    fi
  done #RUBYVERSIONS
  if [ -n "`ls 2>/dev/null *_Installer*.exe`" ]; then
    echo "Done."
  else
    echo "*** Windows Installer package(s) not found!"
  fi
else
  echo "*** Skipping Windows build (no flip found)"
fi

# Debian; use GENERIC_DIR=$DEST/$DISTNAME
echo ""
echo "Build Debian package (build $DEBBUILD)"
cd $DEST
if [ ! -f $DEBNAME.orig.tar.gz ]; then
  ln -s $DISTNAME.tar.gz $DEBNAME.orig.tar.gz
fi
# refresh build directory
rm -rf $DISTNAME
tar zxf $DEBNAME.orig.tar.gz
cd $DISTNAME
# Debian packages love ToDo lists
# we point to the Issues tracker just in case somebody hasn't noticed yet
if [ ! -f TODO.txt ]; then
  echo "Create TODO.txt"
  cat <<EOF > TODO.txt
For open issues, see https://code.google.com/p/geotoad/issues/list
EOF
fi
# add new entry to changelog
if ! grep "geotoad ($VERSION-$DEBBUILD)" debian/changelog ; then
  echo -n "First line of changelog: "
  head -n1 debian/changelog
  echo -n "Adding changelog entry:  "
  # I know there's a "dch" helper for this...
  ed --silent debian/changelog <<EOF
0a
geotoad ($VERSION-$DEBBUILD) unstable; urgency=low

  * New release $VERSION

 -- Steve8x8 <steve8x8@googlemail.com>  $(date --rfc-2822)

.
w
q
EOF
  head -n1 debian/changelog
fi
# build source and binary, do not sign anything, clean afterwards
dpkg-buildpackage >/dev/null -rfakeroot -uc -us -tc
cd $DEST
if [ -z "`ls 2>/dev/null $DEBNAME-${DEBBUILD}_*.deb`" ]; then
  echo "*** Debian package not found!"
else
  echo "Done."
  echo "Build Debian package list(s)"
  # deb http://geotoad.googlecode.com/ svn/trunk/data/
  #     ^-- append files/$filename     ^-- get package list
  dpkg-scanpackages $DEST \
  | sed "s~$DEST/~files/~" \
  | gzip -9 > $DEST/Packages.gz
  false && \
  dpkg-scansources $DEST \
  | sed "s~$DEST/~files/~" \
  | gzip -9 > $DEST/Sources.gz
  if [ -z "$SVN" ]; then
    cp -p *es.gz $INITIALDIR/data/
    echo "*** Do not forget to update the package lists!"
  fi
  echo "Done."
fi

echo ""
cd $DEST
#$#echo "Removing ZIP files"
#$#rm -f *.zip
#$#echo "Done."

echo ""
echo "Files for upload:"
ls -l 2>/dev/null $DISTNAME.tar.gz $DEBNAME-${DEBBUILD}_*.deb ${DISTNAME}_Windows_Installer*.exe ${DISTNAME}_MacOSX.dmg
echo ""
read -p "*** Upload to GoogleCode now? " x
if [ -z "$SVN" ]; then
  . ~/.googlecoderc
  if [ -n "$GOOGLECODEUSER" ]; then
    GCU="googlecode_upload.py --project geotoad --user $GOOGLECODEUSER --password $GOOGLECODEPASS"
  fi
fi
if [ -z "$GCU" ]; then
  echo "*** Fake upload!"
  GCU="echo would upload: "
fi
read -p "*** OK? " x
if [ -f $DISTNAME.tar.gz ]; then
  $GCU \
    -s "geotoad $VERSION source code (requires ruby)" \
    -l "Featured,Type-Source,OpSys-All" \
      $DISTNAME.tar.gz
fi
if [ -n "`ls 2>/dev/null $DEBNAME-${DEBBUILD}_*.deb`" ]; then
  $GCU \
    -s "geotoad $VERSION package for Debian/Ubuntu" \
    -l "Featured,Type-Package,OpSys-Linux" \
      $DEBNAME-${DEBBUILD}_*.deb
fi
if [ -f ${DISTNAME}_Windows_Installer.exe ]; then
  $GCU \
    -s "geotoad $VERSION installer for Windows" \
    -l "Featured,Type-Installer,OpSys-Windows" \
      ${DISTNAME}_Windows_Installer.exe
fi
if [ -f ${DISTNAME}_Windows_Installer_Ruby18.exe ]; then
  $GCU \
    -s "geotoad $VERSION installer for Windows using Ruby 1.8" \
    -l "Featured,Type-Installer,OpSys-Windows" \
      ${DISTNAME}_Windows_Installer_Ruby18.exe
fi
if [ -f ${DISTNAME}_Windows_Installer_Ruby19.exe ]; then
  $GCU \
    -s "geotoad $VERSION installer for Windows using Ruby 1.9" \
    -l "Featured,Type-Installer,OpSys-Windows" \
      ${DISTNAME}_Windows_Installer_Ruby19.exe
fi
if [ -f ${DISTNAME}_Windows_Installer_Ruby20.exe ]; then
  $GCU \
    -s "geotoad $VERSION installer for Windows using Ruby 2.0" \
    -l "Featured,Type-Installer,OpSys-Windows" \
      ${DISTNAME}_Windows_Installer_Ruby20.exe
fi
if [ -f ${DISTNAME}_MacOSX.dmg ]; then
  $GCU \
    -s "geotoad $VERSION package for Mac OS X (requires ruby)" \
    -l "Featured,Type-Installer,OpSys-OSX" \
      ${DISTNAME}_MacOSX.dmg
fi
echo "Done."

echo ""
echo "All done."
