

#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

GCCPATH="/home/ekap/gcc-arm/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc"
if [ ! -d ${GCCPATH} ]; then
 echo "GCC folder not recognized. Fail. ${GCCPATH}"
 exit 1
else 
 echo " PATH to g c c -  ${GCCPATH}"
fi

export PATH="$HOME/gcc-arm/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/bin:$PATH"
OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
export ARCH=arm64
export CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
  echo "Using default directory ${OUTDIR} for output"
else
  OUTDIR=$1
  echo "Using passed directory ${OUTDIR} for output"
fi


#make working folder
mkdir -p ${OUTDIR}
cd "$OUTDIR"

#check if already cloned
if [ ! -d "${OUTDIR}/linux-stable" ]; then
  #Clone only if the repository does not exist.
  echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
  git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
  cd linux-stable
  echo "Checking out version ${KERNEL_VERSION}"
  git checkout ${KERNEL_VERSION}

#EK kernel is built in /linux-stable, incl image (vmlinux uncompressed elf), .ko, .dtb. No user land
#no /bin, /etc no shell


  #TODO: Add your kernel build steps here
  echo "Starting mrproper\n"
  make mrproper
  echo "Generating defconfig\n"
  make defconfig
  echo "Building kernel\n"
  make -j4 all
  echo "Building modules"
  make -j4 modules
  echo "Make device tree blob\n"
  make dtbs
fi

if [ ! -e ${OUTDIR}/Image ]; then
  sudo cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR} 
fi

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"

#EK delete old rootfs
if [ -d "${OUTDIR}/rootfs" ]; then
  echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
  sudo rm  -rf ${OUTDIR}/rootfs
fi

#TODO: Create necessary base directories
mkdir rootfs/
cd rootfs/
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log home/conf 


echo "erviink" > ${OUTDIR}/rootfs/home/conf/username.txt
echo "assignment3" > ${OUTDIR}/rootfs/home/conf/assignment.txt

cd ${OUTDIR}/rootfs/

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
  git clone git://busybox.net/busybox.git
  cd busybox
  git checkout ${BUSYBOX_VERSION}
  # TODO:  Configure busybox
else
  cd busybox
  echo "Current folder is $PWD"
fi

#TODO: Make and install busybox

echo "Install Busybox\n"


make distclean
make defconfig
make -j4
make -j4 CONFIG_PREFIX=${OUTDIR}/rootfs install

echo "Library dependencies"
cd ../rootfs  
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs, program inerpreter to /lib and  shared lib to /lib64

#~/gcc-arm/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc

cp -a /home/ekap/gcc-arm/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1 ./lib
cp -a /home/ekap/gcc-arm/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libm.so.6 ./lib64
cp -a /home/ekap/gcc-arm/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libresolv.so.2 ./lib64
cp -a /home/ekap/gcc-arm/gcc-arm-10.3-2021.07-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc/lib64/libc.so.6 ./lib64


# TODO: Make device nodes
echo "Making device nodes\n"
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

# TODO: Clean and build the writer utility

#go to script folder
echo "Building writer"
cd ${FINDER_APP_DIR}
make clean
make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- writer



# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

cp writer writer.o finder.sh finder-test.sh autorun-qemu.sh  ${OUTDIR}/rootfs/home

#TODO: Chown the root directory - change owner files to root, recursively starting here
#execute as super user, change owner mode recursively user owner:group owner

cd ${OUTDIR}
sudo chown -R root:root rootfs/

#TODO: Create initramfs.cpio.gz

cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd ${OUTDIR}
gzip -f initramfs.cpio
