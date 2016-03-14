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

#
# this script installs the proper git clones into "clones"
# it does not to git subprojects.
# You can also specify a list of "brew" dependencies. That
# will be third party libraries, you don't tag or debug
#
INHERIT_SETTINGS='taps
brews
repositories
pips
gems
settings/build_order
settings/build_ignore'


bootstrap_auto_update()
{
   local name
   local url
   local directory
   local settings


   name="$1"
   url="$2"
   directory="$3"
   settings="$4"

   [ ! -z "${directory}" ]        || internal_fail "src was empty"
   [ "${PWD}" != "${directory}" ] || internal_fail "configuration error"


   # contains own bootstrap ? and not a symlink
   if [ ! -d "${directory}/.bootstrap" ] # -a ! -L "${dst}" ]
   then
      log_fluff "no .bootstrap folder in \"${directory}\" found"
      return 1
   fi

   log_fluff "Recursively acquiring ${directory} .bootstrap settings ..."

   local old

   old="${IFS:-" "}"

   #
   # prepare auto folder if it doesn't exist yet
   # means copy our own files to .auto first,
   #
   if [ ! -d "${BOOTSTRAP_SUBDIR}.auto" ]
   then
      log_fluff "Found a .bootstrap folder for \"${name}\" will set up ${BOOTSTRAP_SUBDIR}.auto"

      mkdir_if_missing "${BOOTSTRAP_SUBDIR}.tmp/settings"

      IFS="
"
      for i in $settings
      do
         IFS="${old}"
         if [ -f "${BOOTSTRAP_SUBDIR}.local/${i}" ]
         then
            exekutor cp "${BOOTSTRAP_SUBDIR}.local/${i}" "${BOOTSTRAP_SUBDIR}.tmp/${i}" || exit 1
         else
            if [ -f "${BOOTSTRAP_SUBDIR}/${i}" ]
            then
               exekutor cp "${BOOTSTRAP_SUBDIR}/${i}" "${BOOTSTRAP_SUBDIR}.tmp/${i}" || exit 1
            else
               local  settingname

               settingname="`basename -- "${i}"`"
               log_fluff "Setting \"${settingname}\" is not specified, so not inherited"
            fi
         fi
      done
      IFS="${old}"

      # now move it
      exekutor mv "${BOOTSTRAP_SUBDIR}.tmp" "${BOOTSTRAP_SUBDIR}.auto" || exit 1

      # leave .scm files behind
   fi

   #
   # prepend new contents to old contents
   # of a few select and known files
   #
   local srcfile
   local dstfile
   local i
   local settingname

   IFS="
"
   for i in $settings
   do
      IFS="{old}"
      srcfile="${directory}/.bootstrap/${i}"
      dstfile="${BOOTSTRAP_SUBDIR}.auto/${i}"
      settingname="`basename -- "${i}"`"

      if [ -f "${srcfile}" ]
      then
         log_fluff "Inheriting \"${settingname}\" from \"${srcfile}\""

         mkdir_if_missing "${BOOTSTRAP_SUBDIR}.auto/`dirname -- "${i}"`"
         if [ -f "${BOOTSTRAP_SUBDIR}.auto/${i}" ]
         then
            local tmpfile

            tmpfile="${BOOTSTRAP_SUBDIR}.auto/${i}.tmp"

            exekutor mv "${dstfile}" "${tmpfile}" || exit 1
            exekutor cat "${srcfile}" "${tmpfile}" > "${dstfile}"  || exit 1
            exekutor rm "${tmpfile}" || exit 1
         else
            exekutor cp "${srcfile}" "${dstfile}" || exit 1
         fi
      else
         log_fluff "Setting \"${settingname}\" is not specified, so not inherited"
      fi
   done
   IFS="{old}"

   # link scm files over, that we find
   local relative

   relative="`compute_relative "${BOOTSTRAP_SUBDIR}"`"
   exekutor find "${directory}/.bootstrap" -xdev -mindepth 1 -maxdepth 1 -name "*.scm" -type f -print0 | \
         exekutor xargs -0 -I % ln -s -f "${relative}/../"% "${BOOTSTRAP_SUBDIR}.auto/${name}"

   #
   # link up other non-inheriting settings
   #
   if dir_has_files "${directory}/.bootstrap/settings"
   then
      local relative

      log_fluff "Link up build settings of \"${name}\" to \"${BOOTSTRAP_SUBDIR}.auto/settings/${name}\""

      mkdir_if_missing "${BOOTSTRAP_SUBDIR}.auto/settings"
      exekutor find "${directory}/.bootstrap/settings" -xdev -mindepth 1 -maxdepth 1 -type f -print0 | \
         exekutor xargs -0 -I % ln -s -f "${relative}/../../"% "${BOOTSTRAP_SUBDIR}.auto/settings/${name}"

      if [ -e "${directory}/.bootstrap/settings/bin"  ]
      then
         exekutor ln -s -f "${relative}/../../${directory}/.bootstrap/settings/bin" "${BOOTSTRAP_SUBDIR}.auto/settings/${name}"
      fi

      # flatten other folders into our own settings
      # don't force though, keep first
      exekutor find "${directory}/.bootstrap/settings" -xdev -mindepth 1 -maxdepth 1 -type d -print0 | \
         exekutor xargs -0 -I % ln -s -f "${relative}/../"% "${BOOTSTRAP_SUBDIR}.auto/settings"
   fi

   return 0
}