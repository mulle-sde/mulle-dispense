#! /bin/sh
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
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
MULLE_BOOTSTRAP_LOCAL_ENVIRONMENT_SH="included"

MULLE_BOOTSTRAP_EXEC_VERSION=2.0  # paranoia

if [ "${MULLE_BOOTSTRAP_EXEC_VERSION}" != "${MULLE_BOOTSTRAP_VERSION}" ]
then
   echo "mulle-bootstrap is misinstalled (${MULLE_BOOTSTRAP_EXEC_VERSION} vs ${MULLE_BOOTSTRAP_VERSION})" >&2
   exit 1
fi

#
# read local environment
# source this file
#
if [ -z "${BOOTSTRAP_SUBDIR}" ]
then
   BOOTSTRAP_SUBDIR=.bootstrap
fi

[ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
[ -z "${MULLE_BOOTSTRAP_MINGW_SH}" ] && . mulle-bootstrap-mingw.sh


MULLE_BOOTSTRAP_TRACE="`read_config_setting "trace"`"

case "${MULLE_BOOTSTRAP_TRACE}" in
   VERBOSE)
      MULLE_BOOTSTRAP_FLUFF="NO"
      MULLE_BOOTSTRAP_TRACE="NO"
      MULLE_BOOTSTRAP_VERBOSE="YES"
      if [ -z "${MULLE_BOOTSTRAP_VERBOSE_BUILD}" ]
      then
         MULLE_BOOTSTRAP_VERBOSE_BUILD="NO"
      fi
      ;;

   FLUFF)
      MULLE_BOOTSTRAP_FLUFF="YES"
      MULLE_BOOTSTRAP_TRACE="NO"
      MULLE_BOOTSTRAP_VERBOSE="YES"
      if [ -z "${MULLE_BOOTSTRAP_VERBOSE_BUILD}" ]
      then
         MULLE_BOOTSTRAP_VERBOSE_BUILD="NO"
      fi
      ;;

   TRACE)
      MULLE_BOOTSTRAP_TRACE_SETTINGS="YES"
      MULLE_BOOTSTRAP_FLUFF="YES"
      MULLE_BOOTSTRAP_VERBOSE="YES"
      MULLE_BOOTSTRAP_TRACE="YES"
      if [ -z "${MULLE_BOOTSTRAP_VERBOSE_BUILD}" ]
      then
         MULLE_BOOTSTRAP_VERBOSE_BUILD="NO"
      fi
      log_trace "FULL trace started"
      ;;

   1848)
      MULLE_BOOTSTRAP_SETTINGS_FLIP_X="YES"
      MULLE_BOOTSTRAP_TRACE_SETTINGS="NO"
      MULLE_BOOTSTRAP_FLUFF="NO"
      MULLE_BOOTSTRAP_TRACE="NO"
      MULLE_BOOTSTRAP_VERBOSE="NO"
      MULLE_BOOTSTRAP_VERBOSE_BUILD="YES"
      log_trace "1848 trace (set -x) started"
      set -x
      ;;
esac


if [ "${MULLE_BOOTSTRAP_DRY_RUN}" = "YES" ]
then
   log_trace "Dry run is active."
fi

# can't rename this because of embedded reposiories
CLONES_SUBDIR=.repos

# future: shared dependencies folder for many projects

RELATIVE_ROOT=""

CLONESBUILD_SUBDIR=`read_sane_config_path_setting "build_foldername" "${RELATIVE_ROOT}build/.repos"`
DEPENDENCY_SUBDIR=`read_sane_config_path_setting "output_foldername" "${RELATIVE_ROOT}dependencies"`
ADDICTION_SUBDIR=`read_sane_config_path_setting "brew_foldername" "${RELATIVE_ROOT}addictions"`
BUILDLOG_SUBDIR=`read_sane_config_path_setting "build_log_foldername" "${CLONESBUILD_SUBDIR}/.logs"`


if [ "${CLONESFETCH_SUBDIR}" = "" ]
then
   CLONESFETCH_SUBDIR="${CLONES_SUBDIR}"
fi


#
# some checks
#
[ -z "${BOOTSTRAP_SUBDIR}" ]     && internal_fail "variable BOOTSTRAP_SUBDIR is empty"
[ -z "${CLONES_SUBDIR}" ]        && internal_fail "variable CLONES_SUBDIR is empty"
[ -z "${CLONESBUILD_SUBDIR}" ]   && internal_fail "variable CLONESBUILD_SUBDIR is empty"
[ -z "${BUILDLOG_SUBDIR}" ]      && internal_fail "variable BUILDLOG_SUBDIR is empty"
[ -z "${DEPENDENCY_SUBDIR}" ]    && internal_fail "variable DEPENDENCY_SUBDIR is empty"
[ -z "${ADDICTION_SUBDIR}" ]     && internal_fail "variable ADDICTION_SUBDIR is empty"

#
# Global Settings
#
HEADER_DIR_NAME="`read_config_setting "header_dir_name" "include"`"
LIBRARY_DIR_NAME="`read_config_setting "library_dir_name" "lib"`"
FRAMEWORK_DIR_NAME="`read_config_setting "framework_dir_name" "Frameworks"`"


#
# dont export stuff for scripts
# if scripts want it, they should source this file
#

UNAME="`uname`"
log_fluff "${UNAME} detected"

# get number of cores, use 50% more for make -j
case "${UNAME}" in
   MINGW*)
      setup_mingw_environment

      PATH_SEPARATOR=';'
      BUILD_PWD_OPTIONS="-PW"
   ;;

   *)
      CORES="`get_core_count`"
      CORES="`expr $CORES + $CORES / 2`"

      PATH_SEPARATOR=':'
      BUILD_PWD_OPTIONS="-P"
      ;;
esac
