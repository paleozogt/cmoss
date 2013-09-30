#!/bin/bash
set -e

# Copyright (c) 2010, Pierre-Olivier Latour
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * The name of Pierre-Olivier Latour may not be used to endorse or
#       promote products derived from this software without specific prior
#       written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Download source
if [ ! -e "icu4c-${ICU_VERSION//./_}-src.tgz" ]
then
	curl $PROXY -O "http://download.icu-project.org/files/icu4c/${ICU_VERSION}/icu4c-${ICU_VERSION//./_}-src.tgz"
fi

# Extract source
rm -rf "icu"
tar xvf "icu4c-${ICU_VERSION//./_}-src.tgz"

# Build

HOSTBUILD=${TMPDIR}/icu-hostbuild
echo "--"
echo $HOSTBUILD
echo "--"

if [ ! -d ${HOSTBUILD} ]
then
	mkdir -p ${HOSTBUILD}
	pushd ${HOSTBUILD}
	${TMPDIR}/icu/source/configure --prefix="${HOSTBUILD}"
	make
	popd
fi

ICU_FLAGS="-I${TMPDIR}/icu/source/common/ -I${TMPDIR}/icu/source/tools/tzcode/"

export LDFLAGS="-Os -arch ${ARCH} -Wl,-dead_strip -miphoneos-version-min=${MIPHONEOS_VERSION_MIN} -L${ROOTDIR}/lib"
export CFLAGS="-Os -arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -miphoneos-version-min=${MIPHONEOS_VERSION_MIN} ${ICU_FLAGS} -I${ROOTDIR}/include"
export CPPFLAGS="${CFLAGS}"
export CXXFLAGS="${CFLAGS}"

echo $LDFLAGS
echo $CFLAGS

pushd "icu/source"
echo ./configure --host=${ARCH}-apple-darwin --prefix=${ROOTDIR} --with-cross-build="${HOSTBUILD}" --enable-static --disable-shared --enable-extras=no --enable-strict=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --with-data-packaging=archive 
./configure --host=${ARCH}-apple-darwin --prefix=${ROOTDIR} --with-cross-build="${HOSTBUILD}" --enable-static --disable-shared --enable-extras=no --enable-strict=no --enable-tests=no --enable-samples=no --enable-dyload=no --enable-tools=no --with-data-packaging=archive

make VERBOSE=1
make install
popd

# Clean up
rm -rf "icu"
