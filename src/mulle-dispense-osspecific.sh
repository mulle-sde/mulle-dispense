# shellcheck shell=bash
#
#   Copyright (c) 2015-2017 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_DISPENSE_OSSPECIFIC_SH='included'


# TODO: move all this to platform

FRAMEWORK_DIR_NAME="${OPTION_FRAMEWORK_DIR_NAME:-Frameworks}"
HEADER_DIR_NAME="${OPTION_HEADER_DIR_NAME:-include}"
LIBRARY_DIR_NAME="${OPTION_LIBRARY_DIR_NAME:-lib}"
LIBEXEC_DIR_NAME="${OPTION_LIBRARY_DIR_NAME:-libexec}"
RESOURCE_DIR_NAME="${OPTION_RESOURCE_DIR_NAME:-share}"
BIN_DIR_NAME="${OPTION_BIN_DIR_NAME:-bin}"
SBIN_DIR_NAME="${OPTION_BIN_DIR_NAME:-sbin}"

#
# TODO: move all of this into MULLE_PLATFORM and query that
#

# overrides from front to back
EXE_SUFFIXES=""

HEADER_SUFFIXES=".h .hpp .inc"
LIBRARY_SUFFIXES=".a .so"
LIBRARY_PREFIX="lib"

case "${MULLE_UNAME}" in
   'darwin')
      LIBRARY_SUFFIXES=".a .dylib"
   ;;

   'mingw'|'msys')
      LIBRARY_SUFFIXES=".lib .dll"
      LIBRARY_PREFIX=""
      SBIN_DIR_NAME=""
      EXE_SUFFIXES=".bat .exe"
   ;;
esac

:

