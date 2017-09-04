#! /usr/bin/env bash
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
#

MULLE_BOOTSTRAP_SYSTEMINSTALL_SH="included"



systeminstall_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} systeminstall [libraryprefix] [frameworkprefix]

   You may need to run this as sudo.
   The default libraryprefix is "${DEFAULT_PREFIX}
   The default frameworkprefix is "${DEFAULT_FRAMEWORK_PREFIX}"

EOF
   exit 1
}


install_libraries_with_action()
{
   log_debug "install_libraries_with_action" "$*"

   local action
   local dstdir
   local srcdir

   action="$1"
   dstdir="${PREFIX}/${LIBRARY_DIR_NAME}"
   srcdir="${DEPENDENCIES_DIR}/${LIBRARY_DIR_NAME}"

   local name
   local owd
   local library

   if [ ! -d "${srcdir}" ]
   then
      return 0
   fi

   owd="`pwd`"
   cd "${srcdir}"

   for library in *
   do
      if [ -f "${library}" ]
      then
         if [ -f "${dstdir}/${library}" ]
         then
            remove_file_if_present "${dstdir}/${library}"
         fi

         log_info "Installing library ${C_MAGENTA}${C_BOLD}${library}${C_INFO} into ${dstdir}..."
         mkdir_if_missing "${dstdir}"
         # don't quote action
         exekutor $action "`pwd`/${library}" "${dstdir}/${library}"
         if [ -x "${dstdir}/${library}" ]
         then
            exekutor chmod 755 "${dstdir}/${library}"
         fi
      fi
   done

   cd "${owd}"
}



install_libraries_by_copying()
{
   install_libraries_with_action "cp -Ra ${COPYMOVEFLAGS}" "$@"
}


install_libraries_by_symlinking()
{
   install_libraries_with_action "ln -s" "$@"
}


install_headers_with_action()
{
   local action
   local dstdir
   local srcdir

   action="$1"
   dstdir="${PREFIX}/${HEADER_DIR_NAME}"
   srcdir="${DEPENDENCIES_DIR}/${HEADER_DIR_NAME}"

   local name
   local owd
   local header

   if [ ! -d "${srcdir}" ]
   then
      return 0
   fi

   owd="`pwd`"
   cd "${srcdir}"

   #
   # copy lonely header files (unusual)
   #
   for header in *.h
   do
      if [ -f "${header}" ]
      then
         if [ -f "${dstdir}/${header}" ]
         then
            remove_file_if_present "${dstdir}/${header}"
         fi
         log_info "Installing header ${C_MAGENTA}${C_BOLD}${header}${C_INFO} into \"${dstdir}\" ..."
         mkdir_if_missing "${dstdir}"
         # don't quote action
         exekutor ${action} "`pwd`/${header}" "${dstdir}/${header}"
      fi
   done

   #
   # copy directories (usual)
   #
   for header in *
   do
      if [ -d "${header}" -a "${header}" != '.' -a "${header}" != '..' ]
      then
         if [ -d "${dstdir}/${header}" ]
         then
            rmdir_safer "${dstdir}/${header}"
         fi
         log_info "Installing headers ${C_MAGENTA}${C_BOLD}${header}${C_INFO} into \"${dstdir}\" ..."
         mkdir_if_missing "${dstdir}"
         # don't quote action
         exekutor ${action} "`pwd`/${header}" "${dstdir}/${header}"
      fi
   done

   cd "${owd}"
}


install_headers_by_copying()
{
   install_headers_with_action "cp -Ra ${COPYMOVEFLAGS}" "$@"
}


install_headers_by_symlinking()
{
   "install_headers_with_action" "ln -s" "$@"
}


determine_framework_suffix()
{
   if [ "${N_CONFIGURATIONS}" -gt 1 ]
   then
      if [ "$1" != "Release" ]
      then
         echo "_$1" | '[:upper:][:lower:]'
      fi
   fi
}


merge_framework_configurations()
{
   local name
   local dstdir
   local srcexe

   name="$1"
   dstdir="$2"
   srcexe="$3"

   local configuration
   local suffix
   local dstexe

   for configuration in ${OPTION_CONFIGURATIONS}
   do
      suffix="`determine_framework_suffix "${configuration}"`"
      if [ ! -z "${suffix}" ]
      then
         dstexe="${dstdir}/${name}${suffix}"
         exekutor cp ${COPYMOVEFLAGS} "${srcexe}" "${dstexe}" >&2
         exekutor chmod 755 "${dstexe}"  >&2
      fi
   done

}


install_frameworks_with_action()
{
   local action
   local dstdir
   local srcexe

   action="$1"
   dstdir="${PREFIX}/${FRAMEWORK_DIR_NAME}"
   srcdir="${DEPENDENCIES_DIR}/${FRAMEWORK_DIR_NAME}"

   local owd
   local framework

   if [ ! -d "${srcdir}" ]
   then
      return 0
   fi

   owd="`pwd`"
   cd "${srcdir}"

   for framework in *.framework
   do
      if [ -d "${framework}" ]
      then
         if [ -d "${dstdir}/${framework}" ]
         then
            rmdir_safer "${dstdir}/${framework}"
         fi

         mkdir_if_missing "${dstdir}"
         log_info "Installing Framework ${C_MAGENTA}${C_BOLD}${framework}${C_INFO} into \"${dstdir}\" ..."
         # don't quote action
         exekutor ${action} "`pwd`/${framework}" "${dstdir}/${framework}"
      fi
   done

   cd "${owd}"
}



install_frameworks_by_copying()
{
   install_frameworks_with_action "cp -Rp" "$@"
}


install_frameworks_by_symlinking()
{
   install_frameworks_with_action "ln -s" "$@"
}


#
# Currently only install the default configuration, which
# is usually "Release"
#
systeminstall_main()
{
   log_debug "::: systeminstall :::"

   [ -z "${MULLE_BOOTSTRAP_COMMON_SETTINGS_SH}" ] && . mulle-bootstrap-common-settings.sh

   DEFAULT_PREFIX="/usr/local"
   DEFAULT_FRAMEWORK_PREFIX="/Library"


   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|--help)
            install_usage
         ;;

         --prefix)
            shift
            [ $# -ne 0 ] || fail "prefix missing"

            DEFAULT_PREFIX="$1"
         ;;

         --framework-prefix)
            shift
            [ $# -ne 0 ] || fail "prefix missing"

            DEFAULT_FRAMEWORK_PREFIX="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown build option $1"
            install_usage
         ;;

         ""|*)
            break
         ;;
      esac

      shift
      continue
   done

   PREFIX="${1:-${DEFAULT_PREFIX}}"
   [ $# -eq 0 ] || shift

   build_complete_environment

   case "${UNAME}" in
      *)
         INSTALL_FRAMEWORKS=
         ;;

      darwin)
         FRAMEWORK_PREFIX="${1:-${DEFAULT_FRAMEWORK_PREFIX}}"
         [ $# -eq 0 ] || shift
         INSTALL_FRAMEWORKS="YES"
         ;;
   esac

   if [ ! -d "${DEPENDENCIES_DIR}" ]
   then
      if [ ! -f "${BOOTSTRAP_DIR}.auto/build_order" ]
      then
         log_info "No repositories fetched, so nothing to build."
         return 0  # not an error really
      fi

      fail "No dependencies have been created yet.
Suggested fix:
   ${MULLE_EXECUTABLE_NAME} build"
   fi

   local symlink

   case "${UNAME}" in
      mingw)
         symlink=
      ;;

      *)
         symlink="`read_config_setting "install_symlinks" "NO"`"
      ;;
   esac

   if [ "${symlink}" = "YES" ]
   then
      install_libraries_by_symlinking "$@"
      install_headers_by_symlinking "$@"
      if [ "${INSTALL_FRAMEWORKS}" = "YES" ]
      then
         install_frameworks_by_symlinking "$@"
      fi
   else
      install_libraries_by_copying "$@"
      install_headers_by_copying "$@"
      if [ "${INSTALL_FRAMEWORKS}" = "YES" ]
      then
         install_frameworks_by_copying "$@"
      fi
   fi
}
