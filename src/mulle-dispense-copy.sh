#! /bin/sh
#
# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
MULLE_DISPENSE_COPY_SH='included'


#
# TODO: Rewrite this completely
#
dispense::copy::usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} copy [options] <srcdir> <dstdir>

   Copy stuff from srcdir to dstdir, possibly reorganizing it on the fly.

   Example:
      MULLE_DISPENSE_SEARCH_LIB_PATH=main/libraster.a \\
         mulle-dispense copy --header-dir include/swrast --copy main /tmp

Options:
   --header-dir <dir>   : specify directory name to place include files
   --lift-headers       : move header files up from subdirectories
   --move               : move instead of copy
   --name <name>        : project name for better logging output
   --mapper-file <file> : a script containing a "r_map_filename" function

EOF
   exit 1
}


r_map_filename()
{
   RVAL="$1"
}


#
# don't use bashfunctions rmdir_safer
#
dispense::copy::rmdir_safer()
{
   [ -z "$1" ] && _internal_fail "empty path"

   if [ -d "$1" ]
   then
      case "${MULLE_UNAME}" in
         'sunos')
            exekutor chmod -R ugo+wX "$1" 2> /dev/null
         ;;
         *)
            exekutor chmod -R ugo+wX "$1" >&2 || fail "Failed to make $1 writable"
         ;;
      esac
      exekutor rm -rf "$1"  >&2 || fail "failed to remove $1"
   fi
}

#
# move stuff produced my cmake and configure to places
# where we expect them. Expect  others to build to
# <prefix>/include  and <prefix>/lib or <prefix>/Frameworks
#
dispense::copy::dispense_file()
{
   local src="$1"
   local dst="$2"

      # special case it's a file
   log_fluff "Dispensing file from \"${src}\" to \"${dst}\""

   # copy flag missing here ?
   rexekutor "${MV_FORCE}" \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MV_FORCE_FLAG} \
               -m "${MV_MAPPER_FUNCTION}" \
               "${src}" \
               "${dst}"
}


dispense::copy::dispense_files()
{
   log_entry "dispense::copy::dispense_files" "$@"

   local src="$1"
   local ftype="$2"
   local dstdir="$3"
   local dirpath="$4"

   [ -z "${src}" ] && return

   local dst

   r_filepath_concat "${dstdir}" "${dirpath}"
   dst="${RVAL}"

   if [ ! -e "${src}" ]
   then
      log_debug "Nothing to dispense from \"${src}\" as it doesn't exist"
      return 1
   fi

   # this can happen if it's a symlink or ?
   if [ ! -d "${src}" ]
   then
      dispense::copy::dispense_file "${src}" "${dst}"  || exit 1
      return
   fi

   if ! dir_has_files "${src}"
   then
      log_debug "Nothing to dispense from \"${src}\", as there are no ${ftype} files"
      return 1
   fi

   mkdir_if_missing "${dst}"

   # this fails with more nested header set ups, need to fix!

   local subsrc

   if [ -z "${dirpath}" ]
   then
      r_basename "${src}"
      r_filepath_concat "${dst}" "${RVAL}"
      dst="${RVAL}"

      mkdir_if_missing "${dst}"
   fi

   .foreachfile subsrc in "${src}"/*
   .do
      dispense::copy::dispense_files "${subsrc}" "${ftype}" "${dst}" || exit 1
   .done

   if [ "${OPTION_MOVE}" = 'YES' ]
   then
      dispense::copy::rmdir_safer "${src}"
   fi
}


dispense::copy::dispense_headers()
{
   log_entry "dispense::copy::dispense_headers" "$@"

   local sources="$1"
   local dstdir="$2"

   local headerpath

   headerpath="${OPTION_HEADER_DIR:-/${HEADER_DIR_NAME}}"

   local src

   .foreachpath src in ${sources}
   .do
      dispense::copy::dispense_files "${src}" "headers" "${dstdir}" "${headerpath}"
   .done
}


dispense::copy::dispense_resources()
{
   log_entry "dispense::copy::dispense_resources" "$@"

   local sources="$1"
   local dstdir="$2"

   local resourcepath

   resourcepath="${OPTION_DISPENSE_RESOURCES_DIR:-/${RESOURCE_DIR_NAME}}"

   local src

   .foreachpath src in ${sources}
   .do
      dispense::copy::dispense_files "${src}" "resources" "${dstdir}" "${resourcepath}"
   .done
}


dispense::copy::do_dispense_binaries()
{
   log_entry "dispense::copy::do_dispense_binaries" "$@"

   local src="$1"
   local findtype="$2"
   local dstdir="$3"
   local subpath="$4"

   [ -z "${src}" ] && return

   local dst
   local findtype2
   local copyflag

   dst="${dstdir}${subpath}"

   findtype2="l"
   copyflag="-f"
   if [ "${findtype}" = "d"  ]
   then
      copyflag="-n"
   fi

   log_debug "Consider dispensing binaries from \"${src}\" for type \"${findtype}/${findtype2}\""

   if [ ! -e "${src}" ]
   then
      log_debug "But it doesn't exist"
      return 1
   fi

   if [ ! -d "${src}" ]
   then
      # special case it's a file
      log_fluff "Dispensing binary from \"${src}\" to \"${dst}\""
      mkdir_if_missing "${dst}"

      rexekutor "${MV_FORCE}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MV_FORCE_FLAG} \
                  -m "${MV_MAPPER_FUNCTION}" \
                  "${copyflag}" \
                  "${src}" \
                  "${dst}/" || exit 1
      return
   fi

   if ! dir_has_files "${src}"
   then
      log_debug "But there are none"
      return
   fi

   log_fluff "Dispensing binaries from \"${src}\" to \"${dst}\""
   mkdir_if_missing "${dst}"

# XARGS wasn't used for unknown reasons, and mingw can't do the find so
# just use `dir_list_files` for now
#
#   # Use XARGS here if available for a bit more parallelism
#   # provide an alternate implementation if xargs isnt there
#   if false && [ ! -z "${XARGS}" ]
#   then
#      rexekutor find "${src}" -xdev \
#                              -mindepth 1 \
#                              -maxdepth 1 \
#                              \( -type "${findtype}" -o -type "${findtype2}" \) \
#                              -print0 \
#      | rexekutor "${XARGS}" -0 \
#                            -I % \
#                            "${MV_FORCE}" \
#                               ${MULLE_TECHNICAL_FLAGS} \
#                               ${MV_FORCE_FLAG} \
#                              -m "${MV_MAPPER_FUNCTION}" \
#                               "${copyflag}" \
#                               % \
#                               "${dst}/" >&2
#   else

   case "${MULLE_UNAME}" in 
      sunos)
         local filenames 
         local filename

         filenames="`dir_list_files "${src}" "" "${findtype}${findtype2}" `"
         .foreachline filename in ${filenames}
         .do 
            if ! "${MV_FORCE}" \
                   ${MULLE_TECHNICAL_FLAGS} \
                   ${MV_FORCE_FLAG} \
                   -m "${MV_MAPPER_FUNCTION}" \
                   "${copyflag}" \
                   "${filename}" \
                   "${dst}/" 
            then
               exit 1
            fi
         .done 
      ;;

      *)
         rexekutor find "${src}" -xdev \
                                 -mindepth 1 \
                                 -maxdepth 1 \
                                 \( -type "${findtype}" -o -type "${findtype2}" \) \
                                 -exec "${MV_FORCE}" \
                                          ${MULLE_TECHNICAL_FLAGS} \
                                          ${MV_FORCE_FLAG} \
                                          -m "${MV_MAPPER_FUNCTION}" \
                                          "${copyflag}" \
                                          {} \
                                          "${dst}/" \
                                          \;
         [ $? -eq 0 ]  || exit 1
      ;;
   esac
}


dispense::copy::dispense_binaries()
{
   log_entry "dispense::copy::dispense_binaries" "$@"

   local binaries="$1" ; shift

   local bin

   .foreachpath bin in ${binaries}
   .do
      dispense::copy::do_dispense_binaries "${bin}" "$@"
   .done
}



dispense::copy::dispense_libexec()
{
   log_entry "dispense::copy::dispense_libexec" "$@"

   local sources="$1"
   local dstdir="$2"

   local libexecpath

   libexecpath="${OPTION_DISPENSE_LIBEXEC_DIR:-/${LIBEXEC_DIR_NAME}}"

   local src

   .foreachpath src in ${sources}
   .do
      dispense::copy::dispense_files "${src}" "libexec" "${dstdir}" "${libexecpath}"
   .done
}


dispense::copy::dispense_libexecs()
{
   log_entry "dispense::copy::dispense_libexecs" "$@"

   local libraries="$1"
   local dstdir="$2"
   local dstpath="$3"

   local lib

   .foreachpath lib in $libraries
   .do
      dispense::copy::dispense_files "${lib}" "f" "${dstdir}" "${dstpath}"
   .done
}


#
# ideally we would have something lile mulle-dispense-library-force.darwin
# which would rewrite the hardcoded paths to @rpath something
#

dispense::copy::dispense_libraries()
{
   log_entry "dispense::copy::dispense_libraries" "$@"

   local libraries="$1"
   local dstdir="$2"
   local dstpath="$3"

   local lib

   .foreachpath lib in $libraries
   .do
      dispense::copy::do_dispense_binaries "${lib}" "f" "${dstdir}" "${dstpath}"
      dispense::copy::do_dispense_binaries "${lib}/pkgconfig" "f" "${dstdir}" "${dstpath}/pkgconfig"
   .done
}


dispense::copy::collect_and_dispense_product()
{
   log_entry "dispense::copy::collect_and_dispense_product" "$@"

   local srcdir="$1"
   local dstdir="$2"

   local MV_FORCE
   local MV_FORCE_FLAG
   local MV_MAPPER_FUNCTION
   local XARGS

   MV_FORCE="${MULLE_DISPENSE_LIBEXEC_DIR}/mulle-dispense-mv-force"
   XARGS="`command -v xargs`"

   if [ "${OPTION_MOVE}" = 'NO' ]
   then
      MV_FORCE_FLAG="-c"
   fi

   MV_MAPPER_FUNCTION="`declare -f r_map_filename`" || exit 1

   # to protect from Xargs escape all percent characters
   # for orneryness escape all ampersands first
   MV_MAPPER_FUNCTION="${MV_MAPPER_FUNCTION//\&/&amp;}"
   MV_MAPPER_FUNCTION="${MV_MAPPER_FUNCTION//\%/&percnt;}"
   # remove windows CRs as bonus
   MV_MAPPER_FUNCTION="${MV_MAPPER_FUNCTION//$'\r'/}"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES'  ]
   then
      log_setting "Contents of srcdir:"

      ls -lRa "${srcdir}" >&2
   fi


   log_fluff "Create default lib/, include/, Frameworks/ in ${dstdir}"
   #
   # ensure basic structure is there to squelch linker warnings
   #

   if [ "${OPTION_HEADERS}" = 'YES' ]
   then
      mkdir_if_missing "${dstdir}/${HEADER_DIR_NAME}"
   fi

   if [ "${OPTION_FRAMEWORKS}" = 'YES' ]
   then
      mkdir_if_missing "${dstdir}/${FRAMEWORK_DIR_NAME}"
   fi

   if [ "${OPTION_LIBRARIES}" = 'YES' ]
   then
      mkdir_if_missing "${dstdir}/${LIBRARY_DIR_NAME}"
   fi

   #
   # TODO: get search paths from mulle_platform ?
   #
   if :
   then
      local sources

      if [ "${OPTION_LIBRARIES}" = 'YES' ]
      then
         ##
         ## copy lib
         ## TODO: isn't cmake's output directory also platform specific ?
         ##
         # order is important, last one wins!
         local searchpath

         RVAL=""
         r_colon_concat "${RVAL}" "${srcdir}/lib"
         r_colon_concat "${RVAL}" "${srcdir}/usr/lib"
         r_colon_concat "${RVAL}" "${srcdir}/usr/local/lib"

         case "${MULLE_UNAME}" in
            linux)
               r_colon_concat "${RVAL}" "${srcdir}/lib/`uname -i`-linux-gnu"
            ;;
         esac
         r_colon_concat "${RVAL}" "${MULLE_DISPENSE_SEARCH_LIB_PATH}"
         searchpath="${RVAL}"

         dispense::copy::dispense_libraries "${searchpath}" "${dstdir}" "/${LIBRARY_DIR_NAME}"

         ##
         ## copy libexec
         ##
         RVAL=""
         r_colon_concat "${RVAL}" "${srcdir}/libexec"
         r_colon_concat "${RVAL}" "${srcdir}/usr/libexec"
         r_colon_concat "${RVAL}" "${srcdir}/usr/local/libexec"

         case "${MULLE_UNAME}" in
            linux)
               r_colon_concat "${RVAL}" "${srcdir}/libexec/`uname -i`-linux-gnu"
            ;;
         esac
         r_colon_concat "${RVAL}" "${MULLE_DISPENSE_SEARCH_LIBEXEC_PATH}"
         searchpath="${RVAL}"

         r_colon_concat "${srcdir}/libexec:${srcdir}/usr/libexec:${srcdir}/usr/local/libexec" \
                        "${MULLE_DISPENSE_SEARCH_LIBEXEC_PATH}"

         dispense::copy::dispense_libexecs "${searchpath}" \
                                           "${dstdir}" \
                                           "${OPTION_DISPENSE_LIBEXEC_DIR:-/${LIBEXEC_DIR_NAME}}"
      fi

      if [ "${OPTION_HEADERS}" = 'YES' ]
      then
         ##
         ## copy headers
         ##
         r_colon_concat "${srcdir}/include:${srcdir}/usr/include:${srcdir}/usr/local/include" \
                        "${MULLE_DISPENSE_SEARCH_INCLUDE_PATH}"
         sources="${RVAL}"

         if [ "${OPTION_LIFT_HEADERS}" = 'YES' ]
         then
            local expanded
            local files 

            .foreachpath i in ${sources}
            .do
               if [ -d "${i}" ]
               then
                  files="`dir_list_files "$i" "" 'd'`"
                  r_add_line "${expanded}" "${files}"
                  expanded="${RVAL}"
               fi
            .done

            sources="${expanded}"
         fi

         dispense::copy::dispense_headers  "${sources}" "${dstdir}"
      fi


      if [ "${OPTION_EXECUTABLES}" = 'YES' ]
      then
         ##
         ## copy bin and sbin
         ##
         r_colon_concat "${srcdir}/bin:${srcdir}/usr/bin:${srcdir}/usr/local/bin" \
                        "${MULLE_DISPENSE_SEARCH_BIN_PATH}"
         dispense::copy::dispense_binaries "${RVAL}" "f" "${dstdir}" "/${BIN_DIR_NAME}"

         r_colon_concat "${srcdir}/sbin:${srcdir}/usr/sbin:${srcdir}/usr/local/sbin" \
                        "${MULLE_DISPENSE_SEARCH_SBIN_PATH}"
         dispense::copy::dispense_binaries "${RVAL}" "f" "${dstdir}" "/${SBIN_DIR_NAME}"
      fi

      if [ "${OPTION_RESOURCES}" = 'YES' ]
      then
         ##
         ## copy resources
         ##
         r_colon_concat "${srcdir}/share:${srcdir}/usr/share:${srcdir}/usr/local/share" \
                        "${MULLE_DISPENSE_SEARCH_SHARE_PATH}"
         dispense::copy::dispense_resources "${RVAL}" "${dstdir}"
      fi

      if [ "${OPTION_FRAMEWORKS}" = 'YES' ]
      then
         ##
         ## copy frameworks
         ##
         r_colon_concat "${srcdir}/System/Library/Frameworks:${srcdir}/Frameworks:${srcdir}/Library/Frameworks" \
                        "${MULLE_DISPENSE_FRAMEWORKS_DIR}"

         dispense::copy::dispense_binaries "${sources}" "d" "${dstdir}" "/${FRAMEWORK_DIR_NAME}"
      fi
   fi

   if [ "${OPTION_MOVE}" = 'YES' ]
   then
      local dst
      local src

      #
      # Delete empty dirs if so
      #
      src="${srcdir}/usr/local"
      if ! dir_has_files "${src}"
      then
         dispense::copy::rmdir_safer "${src}"
      fi

      src="${srcdir}/usr"
      if ! dir_has_files "${src}"
      then
         dispense::copy::rmdir_safer "${src}"
      fi
   fi

   #
   # probably should hack all executables with install_name_tool that contain .ref
   #
   # now copy over the rest of the output
   if [ "${OPTION_DISPENSE_OTHER_PRODUCT}" = 'YES' ]
   then
      local usrlocal

      usrlocal="${OPTION_DISPENSE_OTHER_DIR:-/usr/local}"

      log_fluff "Considering dispensing ${srcdir}/*"

      if dir_has_files "${srcdir}"
      then
         dst="${dstdir}${usrlocal}"

         log_fluff "Dispensing everything from \"${srcdir}\" to \"${dst}\""

         if [ ! -z "${XARGS}" ]
         then
            exekutor find "${srcdir}" -xdev \
                                      -mindepth 1 \
                                      -maxdepth 1 \
                                      -print0 | \
               exekutor "${XARGS}" -0 -I % mv -f % "${dst}/" >&2
         else
            exekutor find "${srcdir}" -xdev \
                                      -mindepth 1 \
                                      -maxdepth 1 \
                                      -exec mv {} "${dst}/" \;
         fi
         [ $? -eq 0 ]  || fail "moving files from ${srcdir} to ${dst} failed"
      fi

      if [ "$MULLE_FLAG_LOG_FLUFF" = 'YES'  ]
      then
         if dir_has_files "${srcdir}"
         then
            log_fluff "Directory \"${dst}\" contains orphaned files after collect and dispense"
            log_fluff "--------------------"
            ( cd "${srcdir}" ; ls -lR >&2 )
            log_fluff "--------------------"
         fi
      fi
   fi

   if [ "${OPTION_MOVE}" = 'YES' ]
   then
      dispense::copy::rmdir_safer "${srcdir}"
   fi

   log_debug "Done collecting and dispensing product"
}


#
# TODO: guessing is in some other project already
#
dispense::copy::r_guess_project_name()
{
   local directory="$1"

   local parent
   local name

   while :
   do
      r_dirname "${directory}"
      parent="${RVAL}"
      r_basename "${directory}"
      name="${RVAL}"

      directory="${parent}"

      if [ "${directory}" = "." ]
      then
         RVAL="${name}"
         return
      fi

      case "${name}" in
         build|Build|Debug|Release|Test|tmp)
         ;;

         *)
            RVAL="${name}"
            return
         ;;
      esac
   done
}


dispense::copy::main()
{
   log_entry "dispense::copy::main" "$@"

   local OPTION_NAME
   local OPTION_MAPPER_FILE
   local OPTION_FRAMEWORKS='DEFAULT'
   local OPTION_LIBRARIES='DEFAULT'
   local OPTION_EXECUTABLES='DEFAULT'
   local OPTION_RESOURCES='DEFAULT'
   local OPTION_HEADERS='DEFAULT'
   local OPTION_LIFT_HEADERS='DEFAULT'
   local OPTION_SHARE='YES'
   local OPTION_MOVE='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            dispense::copy::usage
         ;;

         -c|--copy)
            OPTION_MOVE='NO'
         ;;

         -m|--move)
            OPTION_MOVE='YES'
         ;;

         -n|--name|--project-name)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_NAME="$1"
         ;;

         --no-executables)
            OPTION_EXECUTABLES='NO'
         ;;

         --executables)
            OPTION_EXECUTABLES='YES'
         ;;

         --no-share|--no-resources)
            OPTION_RESOURCES='NO'
         ;;

         --share|--resources)
            OPTION_RESOURCES='YES'
         ;;

         --no-frameworks)
            OPTION_FRAMEWORKS='NO'
         ;;

         --frameworks)
            OPTION_FRAMEWORKS='YES'
         ;;

         --headers)
            OPTION_HEADERS='YES'
         ;;

         --no-headers)
            OPTION_HEADERS='NO'
         ;;

         --lift-headers)
            OPTION_LIFT_HEADERS='YES'
         ;;

         --no-lift-headers)
            OPTION_LIFT_HEADERS='NO'
         ;;

         --only-headers)
            OPTION_HEADERS='YES'
            OPTION_FRAMEWORKS='NO'
            OPTION_LIBRARIES='NO'
            OPTION_EXECUTABLES='NO'
            OPTION_RESOURCES='NO'  # could be generated
         ;;


         --header-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_HEADER_DIR="$1"
         ;;

         --mapper-file)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_MAPPER_FILE="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown dispense option $1"
            dispense::copy::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 2 ] && log_error "not enough arguments ($*)" && dispense::copy::usage

   local srcdir="$1"
   local dstdir="$2"

   [ -z "${srcdir}" ] && fail "Source must not be empty"
   [ -z "${dstdir}" ] && fail "Destination must not be empty"

   [ ! -d "${srcdir}" ] && fail "Source \"${srcdir}\" does not exist"

   [ "${srcdir}" = "${dstdir}" ] && fail "Source and destination must not be same"

   if [ "${FLAG_LS}" = 'YES' ]
   then
      ls -lR "${srcdir}" >&2
      echo >&2
      echo >&2
   fi

   include "dispense::osspecific"

   local name

   name="${OPTION_NAME}"
   if [ -z "${name}" ]
   then
      dispense::copy::r_guess_project_name "${srcdir}"
      name="${RVAL}"
   fi

   [ "${OPTION_HEADERS}" = 'DEFAULT' ]     && OPTION_HEADERS='YES'
   [ "${OPTION_EXECUTABLES}" = 'DEFAULT' ] && OPTION_EXECUTABLES='YES'
   [ "${OPTION_LIBRARIES}" = 'DEFAULT' ]   && OPTION_LIBRARIES='YES'
   [ "${OPTION_RESOURCES}" = 'DEFAULT' ]   && OPTION_RESOURCES='YES'

   if [ "${OPTION_FRAMEWORKS}" = 'DEFAULT' -a "${MULLE_UNAME}" = "darwin" ]
   then
      OPTION_FRAMEWORKS='YES'
   else
      OPTION_FRAMEWORKS='NO'
   fi

   if [ "${OPTION_MAPPER_FILE}" ]
   then
      . "${OPTION_MAPPER_FILE}" || fail "Load of ${OPTION_MAPPER_FILE} failed ($?)"
   fi

   log_fluff "Collecting and dispensing \"${name}\" products"

   dispense::copy::collect_and_dispense_product "${srcdir}" "${dstdir}"
}

