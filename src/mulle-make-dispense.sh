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
MULLE_MAKE_DISPENSE_SH="included"


#
# move stuff produced my cmake and configure to places
# where we expect them. Expect  others to build to
# <prefix>/include  and <prefix>/lib or <prefix>/Frameworks
#
dispense_files()
{
   local src="$1"
   local name="$2"
   local ftype="$3"
   local dispensedir="$4"
   local dirpath="$5"

   local dst

   log_fluff "Consider copying ${ftype} from \"${src}\""


   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then

         dst="`add_component "${dispensedir}" "${dirpath}"`"
         mkdir_if_missing "${dst}"

         # this fails with more nested header set ups, need to fix!

         log_fluff "Copying ${ftype} from \"${src}\" to \"${dst}\""
         exekutor cp -Ra ${COPYMOVEFLAGS} "${src}"/* "${dst}" >&2 || exit 1

         rmdir_safer "${src}"
      else
         log_fluff "But there are none"
      fi
   else
      log_fluff "But it doesn't exist"
   fi
}


dispense_headers()
{
   local sources="$1"
   local name="$2"
   local dispensedir="$3"

   local headerpath

   headerpath="${OPTION_DISPENSE_HEADERS_DIR:-/${HEADER_DIR_NAME}}"

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      dispense_files "${src}" "${name}" "headers" "${dispensedir}" "${headerpath}"
   done
   IFS="${DEFAULT_IFS}"
}


dispense_resources()
{
   local sources="$1"
   local name="$2"
   local dispensedir="$3"

   local resourcepath

   resourcepath="${OPTION_DISPENSE_RESOURCES_DIR:-/${RESOURCE_DIR_NAME}}"

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      dispense_files "${src}" "${name}" "resources" "${dispensedir}" "${resourcepath}"
   done
   IFS="${DEFAULT_IFS}"
}


dispense_libexec()
{
   local sources="$1"
   local name="$2"
   local dispensedir="$3"

   local libexecpath

   libexecpath="${OPTION_DISPENSE_LIBEXEC_DIR:-/${LIBEXEC_DIR_NAME}}"

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      dispense_files "${src}" "${name}" "libexec" "${dispensedir}" "${libexecpath}"
   done
   IFS="${DEFAULT_IFS}"
}


_dispense_binaries()
{
   local src="$1"
   local name="$2"
   local findtype="$3"
   local dispensedir="$4"
   local subpath="$5"

   local dst
   local findtype2
   local copyflag

   findtype2="l"
   copyflag="-f"
   if [ "${findtype}" = "-d"  ]
   then
      copyflag="-n"
   fi
   log_fluff "Consider copying binaries from \"${src}\" for type \"${findtype}/${findtype2}\""

   if [ -d "${src}" ]
   then
      if dir_has_files "${src}"
      then
         dst="${dispensedir}${subpath}"

         log_fluff "Moving binaries from \"${src}\" to \"${dst}\""
         mkdir_if_missing "${dst}"
         exekutor find "${src}" -xdev -mindepth 1 -maxdepth 1 \( -type "${findtype}" -o -type "${findtype2}" \) -print0 | \
            exekutor xargs -0 -I % mulle-make-mv-force ${COPYMOVEFLAGS} "${copyflag}" % "${dst}" >&2
         [ $? -eq 0 ]  || exit 1
      else
         log_fluff "But there are none"
      fi
      rmdir_safer "${src}"
   else
      log_fluff "But it doesn't exist"
   fi
}


dispense_binaries()
{
   local sources="$1" ; shift

   local src
   IFS="
"
   for src in $sources
   do
      IFS="${DEFAULT_IFS}"

      _dispense_binaries "${src}" "$@"
   done
   IFS="${DEFAULT_IFS}"
}


collect_and_dispense_product()
{
   log_debug "_collect_and_dispense_product" "$@"

   local name="$1"
   local builddir="$2"
   local build_subdir="$3"
   local dispensedir="$4"
   local wasxcode="$4"


   log_verbose "Collecting and dispensing \"${name}\" products"

   if [ "${MULLE_FLAG_LOG_DEBUG}" = "YES"  ]
   then
      log_debug "Contents of builddir:"

      ls -lRa ${builddir} >&2
   fi


   #
   # ensure basic structure is there to squelch linker warnings
   #
   log_fluff "Create default lib/, include/, Frameworks/ in ${dispensedir}"

   mkdir_if_missing "${dispensedir}/${FRAMEWORK_DIR_NAME}"
   mkdir_if_missing "${dispensedir}/${LIBRARY_DIR_NAME}"
   mkdir_if_missing "${dispensedir}/${HEADER_DIR_NAME}"

   #
   # probably should use install_name_tool to hack all dylib paths that contain .ref
   # (will this work with signing stuff ?)
   #
   if true
   then
      local sources
      ##
      ## copy lib
      ## TODO: isn't cmake's output directory also platform specific ?
      ##
      sources="${builddir}${build_subdir}/lib
${builddir}/usr/local/lib
${builddir}/usr/lib
${builddir}/lib"

      dispense_binaries "${sources}" "${name}" "f" "${dispensedir}" "/${LIBRARY_DIR_NAME}"

      ##
      ## copy libexec
      ##
      sources="${builddir}${build_subdir}/libexec
${builddir}/usr/local/libexec
${builddir}/usr/libexec
${builddir}/libexec"

      dispense_libexec "${sources}" "${name}" "${dispensedir}"


      ##
      ## copy resources
      ##
      sources="${builddir}${build_subdir}/share
${builddir}/usr/local/share
${builddir}/usr/share
${builddir}/share"

      dispense_resources "${sources}" "${name}" "${dispensedir}"

      ##
      ## copy headers
      ##
      sources="${builddir}${build_subdir}/include
${builddir}/usr/local/include
${builddir}/usr/include
${builddir}/include"

      dispense_headers  "${sources}" "${name}" "${dispensedir}"


      ##
      ## copy bin and sbin
      ##
      sources="${builddir}${build_subdir}/bin
${builddir}/usr/local/bin
${builddir}/usr/bin
${builddir}/bin
${builddir}${build_subdir}/sbin
${builddir}/usr/local/sbin
${builddir}/usr/sbin
${builddir}/sbin"

      dispense_binaries "${sources}" "${name}" "f" "${dispensedir}" "/${BIN_DIR_NAME}"

      ##
      ## copy frameworks
      ##
      sources="${builddir}${build_subdir}/Library/Frameworks
${builddir}${build_subdir}/Frameworks
${builddir}/Library/Frameworks
${builddir}/Frameworks"

      dispense_binaries "${sources}" "${name}" "d" "${dispensedir}" "/${FRAMEWORK_DIR_NAME}"
   fi

   local dst
   local src

   #
   # Delete empty dirs if so
   #
   src="${builddir}/usr/local"
   if ! dir_has_files "${src}"
   then
      rmdir_safer "${src}"
   fi

   src="${builddir}/usr"
   if ! dir_has_files "${src}"
   then
      rmdir_safer "${src}"
   fi

   #
   # probably should hack all executables with install_name_tool that contain .ref
   #
   # now copy over the rest of the output
   if [ "${OPTION_DISPENSE_OTHER_PRODUCT}" = "YES" ]
   then
      local usrlocal

      usrlocal="${OPTION_DISPENSE_OTHER_DIR:-/usr/local}"

      log_fluff "Considering copying ${builddir}/*"

      src="${builddir}"
      if [ "${wasxcode}" = "YES" ]
      then
         src="${src}${build_subdir}"
      fi

      if dir_has_files "${src}"
      then
         dst="${dispensedir}${usrlocal}"

         log_fluff "Copying everything from \"${src}\" to \"${dst}\""
         exekutor find "${src}" -xdev -mindepth 1 -maxdepth 1 -print0 | \
               exekutor xargs -0 -I % mv ${COPYMOVEFLAGS} -f % "${dst}" >&2
         [ $? -eq 0 ]  || fail "moving files from ${src} to ${dst} failed"
      fi

      if [ "$MULLE_FLAG_LOG_VERBOSE" = "YES"  ]
      then
         if dir_has_files "${builddir}"
         then
            log_fluff "Directory \"${dst}\" contained files after collect and dispense"
            log_fluff "--------------------"
            ( cd "${builddir}" ; ls -lR >&2 )
            log_fluff "--------------------"
         fi
      fi
   fi

   rmdir_safer "${builddir}"

   log_fluff "Done collecting and dispensing product"
   log_fluff
}


