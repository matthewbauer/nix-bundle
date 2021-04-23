# Modified from AppImage/pkg2appimage for nix-bundle
[
#
# This file lists libraries that we will assume to be present on the host system and hence
# should NOT be bundled inside AppImages. This is a working document; expect it to change
# over time. File format: one filename per line. Each entry should have a justification comment.

# See the useful tool at https://abi-laboratory.pro/index.php?view=navigator&symbol=hb_buffer_set_cluster_level#result
# to investigate issues with missing symbols.

"ld-linux.so.2"
"ld-linux-x86-64.so.2"
"libanl.so.1"
"libBrokenLocale.so.1"
"libcidn.so.1"
# "libcrypt.so.1" # Not part of glibc anymore as of Fedora 30. See https://github.com/slic3r/Slic3r/issues/4798 and https://pagure.io/fedora-docs/release-notes/c/01d74b33564faa42959c035e1eee286940e9170e?branch=f28
"libc.so.6"
"libdl.so.2"
"libm.so.6"
"libmvec.so.1"
# "libnsl.so.1" # Not part of glibc anymore as of Fedora 28. See https://github.com/RPCS3/rpcs3/issues/5224#issuecomment-434930594
"libnss_compat.so.2"
# "libnss_db.so.2" # Not part of neon-useredition-20190321-0530-amd64.iso
"libnss_dns.so.2"
"libnss_files.so.2"
"libnss_hesiod.so.2"
"libnss_nisplus.so.2"
"libnss_nis.so.2"
"libpthread.so.0"
"libresolv.so.2"
"librt.so.1"
"libthread_db.so.1"
"libutil.so.1"
# These files are all part of the GNU C Library which should never be bundled.
# List was generated from a fresh build of glibc 2.25.

"libstdc++.so.6"
# Workaround for:
# usr/lib/libstdc++.so.6: version `GLIBCXX_3.4.21' not found

"libGL.so.1"
# The above may be missing on Chrome OS, https://www.reddit.com/r/Crostini/comments/d1lp67/ultimaker_cura_no_longer_running_as_an_appimage/
"libEGL.so.1"
# Part of the video driver (OpenGL); present on any regular
# desktop system, may also be provided by proprietary drivers.
# Known to cause issues if it's bundled.

"libGLdispatch.so.0"
"libGLX.so.0"
# reported to be superfluent and conflicting system libraries (graphics driver)
# see https://github.com/linuxdeploy/linuxdeploy/issues/89

# "libOpenGL.so.0" # XXX nix-bundle edit: this was causing problems for me
# Qt installed via install-qt.sh apparently links to this library
# part of OpenGL like libGL/libEGL, so excluding it should not cause any problems
# https://github.com/linuxdeploy/linuxdeploy/issues/152

"libdrm.so.2"
# Workaround for:
# Antergos Linux release 2015.11 (ISO-Rolling)
# /usr/lib/libdrm_amdgpu.so.1: error: symbol lookup error: undefined symbol: drmGetNodeTypeFromFd (fatal)
# libGL error: unable to load driver: swrast_dri.so
# libGL error: failed to load driver: swrast
# Unrecognized OpenGL version

"libglapi.so.0"
# Part of mesa
# known to cause problems with graphics, see https://github.com/RPCS3/rpcs3/issues/4427#issuecomment-381674910

"libgbm.so.1"
# Part of mesa
# https://github.com/probonopd/linuxdeployqt/issues/390#issuecomment-529036305

"libxcb.so.1"
# Workaround for:
# Fedora 23
# symbol lookup error: /lib64/libxcb-dri3.so.0: undefined symbol: xcb_send_fd
# Uncertain if this is required to be bundled for some distributions - if so we need to write a version check script and use LD_PRELOAD to load the system version if it is newer
# Fedora 25:
# undefined symbol: xcb_send_request_with_fds
# https://github.com/AppImage/AppImages/issues/128

"libX11.so.6"
# Workaround for:
# Fedora 23
# symbol lookup error: ./lib/libX11.so.6: undefined symbol: xcb_wait_for_reply64
# Uncertain if this is required to be bundled for some distributions - if so we need to write a version check script and use LD_PRELOAD to load the system version if it is newer

"libgio-2.0.so.0"
# Workaround for:
# On Ubuntu, "symbol lookup error: /usr/lib/x86_64-linux-gnu/gtk-2.0/modules/liboverlay-scrollbar.so: undefined symbol: g_settings_new"

# "libgdk-x11-2.0.so.0" # Missing on openSUSE-Tumbleweed-KDE-Live-x86_64-Snapshot20170601-Media.iso
# "libgtk-x11-2.0.so.0" # Missing on openSUSE-Tumbleweed-KDE-Live-x86_64-Snapshot20170601-Media.iso

"libasound.so.2"
# Workaround for:
# No sound, e.g., in VLC.AppImage (does not find sound cards)

"libgdk_pixbuf-2.0.so.0"
# Workaround for:
# On Ubuntu, get (inkscape:25621): GdkPixbuf-WARNING **: Error loading XPM image loader: Image type 'xpm' is not supported

"libfontconfig.so.1"
# Workaround for:
# Application stalls when loading fonts during application launch; e.g., KiCad on ubuntu-mate

"libthai.so.0"
# Workaround for:
# audacity: /tmp/.mount_AudaciUsFbON/usr/lib/libthai.so.0: version `LIBTHAI_0.1.25' not found (required by /usr/lib64/libpango-1.0.so.0)
# on openSUSE Tumbleweed

# other "low-level" font rendering libraries
# should fix https://github.com/probonopd/linuxdeployqt/issues/261#issuecomment-377522251
# and https://github.com/probonopd/linuxdeployqt/issues/157#issuecomment-320755694
"libfreetype.so.6"
"libharfbuzz.so.0"

# Note, after discussion we do not exlude this, but we can use a dummy library that just does nothing
# libselinux.so.1
# Workaround for:
# sed: error while loading shared libraries: libpcre.so.3: cannot open shared object file: No such file or directory
# Some distributions, such as Arch Linux, do not come with libselinux.so.1 by default.
# The solution is to bundle a dummy mock library:
# echo "extern int is_selinux_enabled(void){return 0;}" >> selinux-mock.c
# gcc -s -shared -o libselinux.so.1 -Wl,-soname,libselinux.so.1 selinux-mock.c 
# strip libselinux.so.1
# More information: https://github.com/AppImage/AppImages/issues/83
# and https://github.com/AppImage/AppImageKit/issues/775#issuecomment-614954821
# https://gitlab.com/sulinos/devel/libselinux-dummy

# The following are assumed to be part of the base system
# Removing these has worked e.g., for Krita. Feel free to report if
# you think that some of these should go into AppImages and why.
"libcom_err.so.2"
"libexpat.so.1"
"libgcc_s.so.1"
"libglib-2.0.so.0"
"libgpg-error.so.0"
# "libgssapi_krb5.so.2" # Disputed, seemingly needed by Arch Linux since Kerberos is named differently there
# "libgssapi.so.3" # Seemingly needed when running Ubuntu 14.04 binaries on Fedora 23
# "libhcrypto.so.4" # Missing on openSUSE LEAP 42.0
# "libheimbase.so.1" # Seemingly needed when running Ubuntu 14.04 binaries on Fedora 23
# "libheimntlm.so.0" # Seemingly needed when running Ubuntu 14.04 binaries on Fedora 23
# "libhx509.so.5" # Missing on openSUSE LEAP 42.0
"libICE.so.6"
# "libidn.so.11" # Does not come with Solus by default
# "libk5crypto.so.3" # Runnning AppImage built on Debian 9 or Ubuntu 16.04 on an Archlinux fails otherwise; https://github.com/AppImage/AppImages/issues/301
# "libkeyutils.so.1" # Does not come with Void Linux by default; https://github.com/Subsurface-divelog/subsurface/issues/1971#issuecomment-466606834
# "libkrb5.so.26" # Disputed, seemingly needed by Arch Linux since Kerberos is named differently there. Missing on openSUSE LEAP 42.0
# "libkrb5.so.3" # Disputed, seemingly needed by Arch Linux since Kerberos is named differently there
# "libkrb5support.so.0" # Disputed, seemingly needed by Arch Linux since Kerberos is named differently there
"libp11-kit.so.0"
# "libpcre.so.3" # Missing on Fedora 24, SLED 12 SP1, and openSUSE Leap 42.2
# "libroken.so.18" # Mission on openSUSE LEAP 42.0
# "libsasl2.so.2" # Seemingly needed when running Ubuntu 14.04 binaries on Fedora 23
"libSM.so.6"
"libusb-1.0.so.0"
"libuuid.so.1"
# "libwind.so.0" # Missing on openSUSE LEAP 42.0
"libz.so.1"

# Potentially dangerous libraries
"libgobject-2.0.so.0"

# Workaround for:
# Rectangles instead of fonts
# https://github.com/AppImage/AppImages/issues/240
"libpangoft2-1.0.so.0"
"libpangocairo-1.0.so.0"
"libpango-1.0.so.0"

# FIXME:
# Can get symbol lookup error: /lib64/libpango-1.0.so.0: undefined symbol: g_log_structured_standard
# if libcairo is bundled but libpango is not

# Workaround for:
# e.g., Spotify
# relocation error: /lib/x86_64-linux-gnu/libgcrypt.so.20: 
# symbol gpgrt_lock_lock, version GPG_ERROR_1.0 not defined
# in file libgpg-error.so.0 with link time reference
"libgpg-error.so.0"

"libjack.so.0"
# it must match the ABI of the JACK server which is installed in the base system
# rncbc confirmed this
# However, this library is missing on Fedora-WS-Live-31-1-9
# which means that we should avoid using JACK altogether if possible

# Unsolved issue:
# https://github.com/probonopd/linuxdeployqt/issues/35
# Error initializing NSS with a persistent database (sql:/home/me/.pki/nssdb): libsoftokn3.so: cannot open shared object file: No such file or directory
# Error initializing NSS without a persistent database: NSS error code: -5925
# nss_error=-5925, os_error=0
# libnss3.so should not be removed from the bundles, as this causes other issues, e.g.,
# https://github.com/probonopd/linuxdeployqt/issues/35#issuecomment-256213517
# and https://github.com/AppImage/AppImages/pull/114
# "libnss3.so"

# The following cannot be excluded, see
# https://github.com/AppImage/AppImages/commit/6c7473d8cdaaa2572248dcc53d7f617a577ade6b
# http://stackoverflow.com/questions/32644157/forcing-a-binary-to-use-a-specific-newer-version-of-a-shared-library-so
# "libssl.so.1"
# "libssl.so.1.0.0"
# "libcrypto.so.1"
# "libcrypto.so.1.0.0"

# According to https://github.com/RicardoEPRodrigues/3Engine/issues/4#issuecomment-511598362
# libGLEW is not tied to a specific GPU. It's linked against libGL.so.1 
# and that one is different depending on the installed driver. 
# In fact libGLEW is changing its soversion very often, so you should always bundle libGLEW.so.2.0

# "libglut.so.3" # to be confirmed

"libxcb-dri3.so.0" # https://github.com/AppImage/AppImages/issues/348
"libxcb-dri2.so.0" # https://github.com/probonopd/linuxdeployqt/issues/331#issuecomment-442276277

# If the next line turns out to cause issues, we will have to remove it again and find another solution
"libfribidi.so.0" # https://github.com/olive-editor/olive/issues/221 and https://github.com/knapsu/plex-media-player-appimage/issues/14

# Workaround for:
# symbol lookup error: /lib/x86_64-linux-gnu/libgnutls.so.30: undefined symbol: __gmpz_limbs_write
# https://github.com/ONLYOFFICE/appimage-desktopeditors/issues/3
# Apparently coreutils depends on it, so it should be safe to assume that it comes with every target system
"libgmp.so.10"

]
