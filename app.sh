### LIBTIRPC ###
_build_libtirpc() {
local VERSION="1.3.3"
local FOLDER="libtirpc-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://sourceforge.net/projects/libtirpc/files/libtirpc/${VERSION}/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
#cp -vf "src/${FOLDER}-api_fixes-1.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
#patch -p1 -i "${FOLDER}-api_fixes-1.patch"
aclocal
automake
# /etc adjustment
sed -i -e "s|/etc/netconfig|${DEST}/etc/netconfig|g" tirpc/netconfig.h
# /var adjustment
sed -e "s|/var|$DEST/var|g" -i tirpc/rpc/rpcb_prot.x
sed -e "s|/var|$DEST/var|g" -i tirpc/rpc/rpcb_prot.h

./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --disable-gssapi
make
make install
mkdir -p "${DEST}/etc"
cp -vf "${DEPS}/etc/netconfig" "${DEST}/etc/netconfig.default"
popd
}

### RPCBIND ###
_build_rpcbind() {
local VERSION="1.2.6"
local FOLDER="rpcbind-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://sourceforge.net/projects/rpcbind/files/rpcbind/${VERSION}/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
# /var adjustment
sed -e "s|/var|$DEST/var|g" -i src/rpcbind.c

PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEST}" \
  --mandir="${DEST}/man" \
  --without-systemdsystemunitdir
make
make install
popd
}

### LIBBLKID ###
_build_libblkid() {
local VERSION="2.39.2"
local FOLDER="util-linux-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="https://www.kernel.org/pub/linux/utils/util-linux/v2.27/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" \
  --libdir="${DEST}/lib" --disable-static \
  --without-systemd --without-ncurses --without-termcap --without-tinfo --without-python \
  --without-bashcompletiondir --disable-all-programs --disable-colors-default \
  --enable-libblkid
make
make install
ln -vfs "libblkid.so.1.1.0" "${DEST}/lib/libblkid.so"
popd
}

### NFSUTILS ###
_build_nfsutils() {
local VERSION="2.6.3"
local FOLDER="nfs-utils-${VERSION}"
local FILE="${FOLDER}.tar.bz2"
local URL="http://sourceforge.net/projects/nfs/files/nfs-utils/${VERSION}/${FILE}"
local files

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"

# /etc adjustment
files="support/include/nfslib.h utils/mount/configfile.c utils/gssd/gssd.h utils/gssd/svcgssd.c utils/nfsidmap/nfsidmap.c"
for f in $files; do
  sed -e "s|/etc|${DEST}/etc|g" -i $f
done

# /sbin adjustment
sed -e "s|/usr/sbin|$DEST/sbin|g" -i utils/statd/statd.c
sed -e "s|PATH=/sbin:/usr/sbin|PATH=/sbin:/usr/sbin:${DEST}/sbin|g" -i utils/statd/start-statd

files="utils/osd_login/Makefile.in utils/mount/Makefile.in utils/nfsdcltrack/Makefile.in"
for f in $files; do
  sed -e "s|^sbindir = /sbin|sbindir = ${DEST}/sbin|g" -i $f
done

# /var adjustment
sed -e "s|/var|${DEST}/var|g" -i utils/mount/nfs4mount.c

files="tests/test-lib.sh utils/statd/statd.man utils/statd/start-statd utils/statd/statd.c"
for f in $files; do
  sed -e "s|/var/run/rpc.statd.pid|/tmp/DroboApps/nfs/rpc.statd.pid|g" -i $f
done

files="utils/blkmapd/device-discovery.c"
for f in $files; do
  sed -e "s|/var/run/blkmapd.pid|/tmp/DroboApps/nfs/blkmapd.pid|g" -i $f
done

files="utils/statd/sm-notify.c"
for f in $files; do
  sed -e "s|/var/run/sm-notify.pid|/tmp/DroboApps/nfs/sm-notify.pid|g" -i $f
done

files="support/include/exportfs.h utils/statd/sm-notify.c utils/idmapd/idmapd.c utils/mount/nfs4mount.c utils/gssd/gssd.h utils/blkmapd/device-discovery.c"
for f in $files; do
  sed -e "s|\"/var/lib|\"${DEST}/var/lib|g" -i $f
done

PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEST}" --exec-prefix="${DEST}" \
  --sbindir="${DEST}/sbin" --mandir="${DEST}/man" \
  --disable-static \
  --with-statedir="${DEST}/var/lib/nfs" \
  --with-statdpath="${DEST}/var/lib/nfs" \
  --with-statduser=nobody \
  --with-start-statd="${DEST}/sbin/start-statd" \
  --with-mountfile="${DEST}/etc/nfsmounts.conf" \
  --without-systemd --without-tcp-wrappers \
  --enable-tirpc --enable-ipv6 --disable-nfsv4 --disable-nfsv41 --disable-gss \
  CC_FOR_BUILD="${CC}" libblkid_cv_is_recent=yes
make
make install
mkdir -p "${DEST}/etc/exports.d" "${DEST}/var/lib/nfs/statd" "${DEST}/var/lib/nfs/v4recovery" "${DEST}/var/lock/subsys" "${DEST}/var/log" "${DEST}/var/run"
# Drobos do not support NFSv4 clients
rm -vf "${DEST}/sbin/mount.nfs4" "${DEST}/sbin/umount.nfs4"
popd
}

### MONIT ###
_build_monit() {
local VERSION="5.33.0"
local FOLDER="monit-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://mmonit.com/monit/dist/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --bindir="${DEST}/libexec" \
  --sysconfdir="${DEST}/etc" \
  --enable-static --disable-shared \
  --without-pam --without-ssl \
  libmonit_cv_setjmp_available=yes libmonit_cv_vsnprintf_c99_conformant=yes
make
make install
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${DEST}/libexec/monit"
popd
}

_build() {
  _build_libtirpc
  _build_rpcbind
  _build_libblkid
  _build_nfsutils
  _build_monit
  _package
}
