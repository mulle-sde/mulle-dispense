#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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

MULLE_BOOTSTRAP_PROJECT_SH="included"

#
# master/minion repository stuff
#

#
# a master does not have a .bootstrap repository
# only .bootstrap.local
#
make_master_bootstrap_project()
{
   log_entry "make_master_bootstrap_project" "$@"

   local masterpath="${1:-.}"

   if [ -d "${masterpath}/${BOOTSTRAP_DIR}" ]
   then
      fail "Can't make \"${masterpath}\" a master repository, because it has a .bootstrap folder"
   fi

   create_file_if_missing "${masterpath}/${BOOTSTRAP_DIR}.local/is_master"
   _create_file_if_missing "${masterpath}/${BOOTSTRAP_DIR}.local/version" \
                           "${MULLE_EXECUTABLE_VERSION_MAJOR}"
}


make_minion_bootstrap_project()
{
   log_entry "make_minion_bootstrap_project" "$@"

   local minionpath="${1:-.}"
   local masterpath="${2:-.}"

   [ $# -eq 2 ] || internal_fail "parameter error"

   masterpath="`symlink_relpath "${masterpath}" "${minionpath}"`"

   mkdir_if_missing "${minionpath}/${BOOTSTRAP_DIR}.local"
   redirect_exekutor "${minionpath}/${BOOTSTRAP_DIR}.local/is_minion" echo "${masterpath}"
}


can_be_master_bootstrap_project()
{
   log_entry "can_be_master_bootstrap_project" "$@"

   local  masterpath="${1:-.}"

   [ ! -d "${masterpath}/${BOOTSTRAP_DIR}" ]
}


make_master_bootstrap_project()
{
   log_entry "make_master_bootstrap_project" "$@"

   local  masterpath="${1:-.}"

   create_file_if_missing "${masterpath}/${BOOTSTRAP_DIR}.local/is_master"
   _create_file_if_missing "${masterpath}/${BOOTSTRAP_DIR}.local/version" "$MULLE_EXECUTABLE_VERSION_MAJOR"
}


emancipate_minion_bootstrap_project()
{
   log_entry "emancipate_minion_bootstrap_project" "$@"

   local minionpath="${1:-.}"

   exekutor rm "${minionpath}/${BOOTSTRAP_DIR}.local/is_minion"  >&2
}


get_master_of_minion_bootstrap_project()
{
   log_entry "get_master_of_minion_bootstrap_project" "$@"

   local minionpath="${1:-.}"

   egrep -s -v '^#|^[ ]*$' "${minionpath}/${BOOTSTRAP_DIR}.local/is_minion"
   :
}


get_master_bootstrap_version()
{
   log_entry "get_master_bootstrap_version" "$@"

   local masterpath="${1:-.}" ; shift

   __read_setting "${masterpath}/${BOOTSTRAP_DIR}.local/version"
}


master_owns_minion_bootstrap_project()
{
   log_entry "master_owns_minion_bootstrap_project" "$@"

   local masterpath="${1:-.}" ; shift
   local minionpath="${1:-.}" ; shift

   minionpath="`symlink_relpath "${minionpath}" "${masterpath}"`"
   if [ ! -f "${masterpath}/${BOOTSTRAP_DIR}.local/minions" ]
   then
      return 1
   fi
   fgrep -q -s -x "${minionpath}" "${masterpath}/${BOOTSTRAP_DIR}.local/minions"
}


_copy_environment_files()
{
   log_entry "_copy_environment_files" "$@"

   local src="${1:-.}" ; shift
   local dst="${1:-.}" ; shift

   local srcfiles
   local name
   local srcfile
   local dstfile

   srcfiles="`find "${src}" -xdev -mindepth 1 -maxdepth 1 -name "[A-Z_]*" -type f -print 2> /dev/null`"
   IFS="
"
   for srcfile in ${srcfiles}
   do
      name="`basename -- "${srcfile}"`"

      IFS="${DEFAULT_IFS}"
      dstfile="${dst}/${name}"

      _copy_no_clobber_setting_file "${srcfile}" "${dstfile}"
   done

   IFS="${DEFAULT_IFS}"
}


master_add_minion_bootstrap_project()
{
   log_entry "master_add_minion_bootstrap_project" "$@"

   local masterpath="${1:-.}" ; shift
   local minionpath="${1:-.}" ; shift

   mkdir_if_missing "${masterpath}/${BOOTSTRAP_DIR}.local"

   minionpath="`symlink_relpath "${minionpath}" "${masterpath}"`"
   redirect_append_exekutor "${masterpath}/${BOOTSTRAP_DIR}.local/minions" \
      echo "${minionpath}"

   #
   # copy over environment files
   #
   _copy_environment_files "${minionpath}/${BOOTSTRAP_DIR}.local" "${masterpath}/${BOOTSTRAP_DIR}.local"
   _copy_environment_files "${minionpath}/${BOOTSTRAP_DIR}"       "${masterpath}/${BOOTSTRAP_DIR}.local"

   exekutor touch "${masterpath}/${BOOTSTRAP_DIR}.local"
}


#
# https://superuser.com/questions/422459/substitution-in-text-file-without-regular-expressions
#
master_remove_minion_bootstrap_project()
{
   log_entry "master_remove_minion_bootstrap_project" "$@"

   local masterpath="${1:-.}" ; shift
   local minionpath="${1:-.}" ; shift
   local unregex
   local filepath

   minionpath="`symlink_relpath "${minionpath}" "${masterpath}"`"
   unregex="`sed -e 's/[]\/()$*.^|[]/\\&/g' <<< "${minionpath}"`"
   filepath="${masterpath}/${BOOTSTRAP_DIR}.local/minions"

   if [ -f "${filepath}" ]
   then
      exekutor sed -i"" -e "/^${unregex}$/d" "${filepath}"

      if [ -z "`read_setting "${filepath}"`" ]
      then
         remove_file_if_present "${filepath}"

         # not be master anymore if last one is gone ?
         remove_file_if_present "${masterpath}/${BOOTSTRAP_DIR}.local/is_master"
         rmdir_if_empty "${masterpath}/${BOOTSTRAP_DIR}.local"
         return
      fi
   fi

   exekutor touch "${masterpath}/${BOOTSTRAP_DIR}.local"
}


project_initialize()
{
#  don't do it, so far it's been overkill
#   source_environment
   log_debug ":project_initialize:"

   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ]   && . mulle-bootstrap-logging.sh
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ]  && . mulle-bootstrap-settings.sh
   :
}

project_initialize

