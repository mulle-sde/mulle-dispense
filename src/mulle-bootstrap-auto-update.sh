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
MULLE_BOOTSTRAP_AUTO_UPDATE_SH="included"


#
# only to be used in bootstrap_auto_create
#
_bootstrap_auto_copy()
{
   local dst="$1"
   local src="$2"
   local is_local="$3"

   #
   # add stuff from bootstrap folder
   # don't copy config if exists (it could be malicious)
   #
   local filepath
   local dstfilepath
   local name
   local value
   local match
   local tmpdir

   #
   # this first stage folds platform specific files
   #
   tmpdir="`mktemp -d /tmp/mulle-bootstrap.XXXXXXXX`"
   inherit_files "${tmpdir}" "${src}"

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"
   IFS="
"
   for name in `ls -1 "${tmpdir}"` # uppercase first is important!
   do
      IFS="${DEFAULT_IFS}"

      filepath="${tmpdir}/${name}"
      dstfilepath="${dst}/${name}"

      case "${name}" in
         config)
            if [ "${is_local}" = "YES" ]
            then
               exekutor cp -Ran ${COPYMOVETARFLAGS} "${filepath}" "${dstfilepath}"
            fi
         ;;

         *.build|settings|overrides)
            if [ -d "${filepath}" ]
            then
               exekutor cp -Ran ${COPYMOVETARFLAGS} "${filepath}" "${dstfilepath}"
            fi
         ;;

         *)
            # only inherit, don't override
            if [ -e "${dstfilepath}" ]
            then
               continue
            fi

            #
            # root settings get the benefit of expansion
            #
            if [ -d "${filepath}" ]
            then
               continue
            fi

            match="`echo "${filepath}" | sed '/[a-z]/d'`"
            if [ -z "${match}" ] ## has lowercase (not environment)
            then
               log_fluff "Copy expanded value of \"${filepath}\""
               value="`_read_expanded_setting "${filepath}" "${name}" "" "${tmpdir}"`"
               redirect_exekutor "${dstfilepath}" echo "${value}"
            else
               exekutor cp -a ${COPYMOVETARFLAGS} "${filepath}" "${dstfilepath}"
            fi
         ;;
      esac
   done

   # rmdir_safer "${tmpdir}"
}


#
# This function is called initially to setup .bootstrap.auto before
# doing anything else. It is clear that .bootstrap.auto does not exist
#
# copy contents of .bootstrap.local to .bootstrap.auto
# them add contents of .bootstrap to .bootstrap.auto, if not present
#
_bootstrap_auto_create()
{
   local dst="$1"
   local src="$2"

   [ -z "${src}" ] && internal_fail "empty bootstrap"

   log_fluff "Creating clean \"${dst}\" from \"${src}\""

   assert_mulle_bootstrap_version

   rmdir_safer "${dst}"
   mkdir_if_missing "${dst}"

   #
   # Copy over .local with config
   #
   if dir_has_files "${src}.local"
   then
      _bootstrap_auto_copy "${dst}" "${src}.local" "YES"
   fi

   #
   # add stuff from bootstrap folder
   # don't copy config if exists (it could be malicious)
   #
   if dir_has_files "${src}"
   then
      _bootstrap_auto_copy "${dst}" "${src}" "NO"
   fi
}


bootstrap_auto_create()
{
   _bootstrap_auto_create "${BOOTSTRAP_DIR}.auto" "${BOOTSTRAP_DIR}"
}



_bootstrap_merge_expanded_settings_in_front()
{
   local addition="$1"
   local original="$2"

   local settings1
   local settings2
   local name

   name="`basename -- "$1"`"
   srcbootstrap="`dirname -- "${1}"`"

   settings1="`_read_expanded_setting "$1" "${name}" "" "${srcbootstrap}"`"
   if [ ! -z "$2" ]
   then
      settings2="`_read_setting "$2" "${name}"`"
   fi

   _merge_settings_in_front "${settings1}" "${settings2}"
}


_make_master_clones()
{
   local clones="$1"

   local clone
   local name       # name of the clone
   local url        # url of clone
   local branch
   local scm
   local tag
   local stashdir   # dir of repository (usually inside stashes)

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      parse_clone "${clone}"

      echo "${url};${name};${branch};${scm};${tag}" | sed 's/;*$//'
   done

   IFS="${DEFAULT_IFS}"
}


_remove_dstdir_from_clones()
{
   local clones="$1"

   local clone
   local name       # name of the clone
   local url        # url of clone
   local branch
   local scm
   local tag
   local stashdir   # dir of repository (usually inside stashes)

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      parse_clone "${clone}"

      echo "${url};;${branch};${scm};${tag}" | sed 's/;*$//'
   done

   IFS="${DEFAULT_IFS}"
}

#
# prepend new contents to old contents
# of a few select and known files, these are merged with whats there
# `BOOTSTRAP_DIR` is the "root" bootstrap to update
# `directory` can be the inferior bootstrap of a fetched repository
#
_bootstrap_auto_merge_root_settings()
{
   dst="$1"
   directory="$2"

   [ -z "${directory}" ] && internal_fail "wrong"

   local srcfile
   local dstfile
   local tmpfile
   local settingname
   local match
   local i

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   IFS="
"
   for i in `ls -1 "${directory}/.bootstrap"`
   do
      IFS="${DEFAULT_IFS}"

      settingname="`basename -- "${i}"`"
      srcfile="${directory}/.bootstrap/${settingname}"
      if [ -d "${srcfile}" ]
      then
         log_fluff "Directory \"${srcfile}\" not copied"
         continue
      fi

      dstfile="${dst}/${settingname}"

      #
      # "repositories" file gets special treatment
      #
      if [ "${settingname}" = "repositories" ]
      then
         local newcontents

         newcontents="`_bootstrap_merge_expanded_settings_in_front "${srcfile}" ""`"
         if is_master_bootstrap_project
         then
            newcontents="`_make_master_clones "${newcontents}"`"
         else
            newcontents="`_remove_dstdir_from_clones "${newcontents}"`"
         fi

         if [ -f "${dstfile}" ]
         then
            local contents2

            contents="`cat "${dstfile}"`"
            newcontents="`merge_repository_contents "${contents}" "${newcontents}"`"
         fi
         log_fluff "Copying expanded \"repositories\" from \"${srcfile}\""

         redirect_exekutor "${dstfile}" echo "${newcontents}"
         continue
      fi

      # #
      # # non mergable settings are not merged
      # #
      # match="`echo "${NON_MERGABLE_SETTINGS}" | fgrep -s -x "${settingname}"`"
      # if [ ! -z "${match}" ]
      # then
      #    log_fluff "Setting \"${settingname}\" is not mergable, so ignored"
      #    continue
      # fi

      # #
      # # environment is not copied over
      # #
      # match="`egrep -s -x "^[A-Z_]+$" <<< "${settingname}"`"
      # if [ ! -z "${match}" ]
      # then
      #    log_fluff "Setting \"${settingname}\" is environment, so ignored"
      #    continue
      # fi

      match="`echo "${MERGABLE_SETTINGS}" | fgrep -s -x "${settingname}"`"
      if [ -z "${match}" ]
      then
         log_fluff "Setting \"${settingname}\" is not mergable, so ignored"
         continue
      fi

      if [ -f "${dstfile}" ]
      then
         tmpfile="${BOOTSTRAP_DIR}.auto/${settingname}.tmp"

         log_fluff "Merging expanded \"${settingname}\" from \"${srcfile}\""

         exekutor mv ${COPYMOVETARFLAGS}  "${dstfile}" "${tmpfile}" >&2 || exit 1
         redirect_exekutor "${dstfile}" _bootstrap_merge_expanded_settings_in_front "${srcfile}" "${tmpfile}"  || exit 1
         exekutor rm ${COPYMOVETARFLAGS}  "${tmpfile}" >&2 || exit 1
      else
         log_fluff "Copying expanded \"${settingname}\" from \"${srcfile}\""

         redirect_exekutor "${dstfile}" _bootstrap_merge_expanded_settings_in_front "${srcfile}" ""
      fi
   done

   IFS="${DEFAULT_IFS}"
}


_bootstrap_auto_embedded_copy()
{
   local name="$1"
   local directory="$2"
   local srcfile="$3"

   local dst

   dst="${BOOTSTRAP_DIR}.auto/.deep/${name}.d"

   [ -d "${dst}" ] && internal_fail "${dst} already exists"
   mkdir_if_missing "${dst}"

   # copy over our stuff
   # _bootstrap_auto_create "${dst}" "${BOOTSTRAP_DIR}"

   # then augment with embedded_settings
   local clones

   clones="`_bootstrap_merge_expanded_settings_in_front "${srcfile}" ""`" || exit 1
   redirect_exekutor "${dst}/embedded_repositories" echo "${clones}"
}


bootstrap_auto_update()
{
   local name="$1"
   local stashdir="$2"

   log_fluff ":bootstrap_auto_update: begin"

   if [ -d "${stashdir}/${BOOTSTRAP_DIR}" ]
   then
      _bootstrap_auto_merge_root_settings "${BOOTSTRAP_DIR}.auto" "${stashdir}"
      sort_repository_file "${stashdir}"

      local srcfile

      srcfile="${stashdir}/${BOOTSTRAP_DIR}/embedded_repositories"
      if [ -f "${srcfile}" ]
      then
         _bootstrap_auto_embedded_copy "${name}" "${stashdir}" "${srcfile}"
      fi
   else
      # could be helpful to user
      if [ -d "${stashdir}/${BOOTSTRAP_DIR}.local" ]
      then
         log_fluff "Inferior \"${stashdir}/${BOOTSTRAP_DIR}.local\" ignored"
      fi
   fi

   log_fluff ":bootstrap_auto_update: end"
}


bootstrap_create_build_folders()
{
   #
   # now pick up on build order and produce .build folders
   # but build order could be "hand coded", lets use it
   #
   local revclonenames
   local clonenames
   local srcdir
   local dstdir

   local has_settings
   local has_overrides

   [ -d "${BOOTSTRAP_DIR}.auto/settings" ]
   has_settings=$?

   [ -d "${BOOTSTRAP_DIR}.auto/overrides" ]
   has_overrides=$?

   clonenames="`read_root_setting "build_order"`"
   revclonenames="`echo "${clonenames}" | sed '1!G;h;$!d'`"  # reverse lines

   local tmp
   local apath
   local name
   local revname

   #
   # small optimization,
   # throw out revclones  that have no .bootstrap folder
   #

   tmp="${revclonenames}"
   revclonenames=""

   IFS="
"
   for revname in ${tmp}
   do
      IFS="${DEFAULT_IFS}"

      apath="`stash_of_repository "${REPOS_DIR}" "${revname}"`/.bootstrap"
      if [ -d "${apath}" ]
      then
         revclonenames="`add_line "${revclonenames}" "${revname}"`"
      fi
   done

   IFS="
"
   for name in ${clonenames}
   do
      IFS="${DEFAULT_IFS}"

      dstdir="${BOOTSTRAP_DIR}.auto/${name}.build"
      if [ ${has_settings} -eq 0 ]
      then
         inherit_files "${dstdir}" "${BOOTSTRAP_DIR}.auto/settings"
      fi

      if [ "`read_build_setting "${name}" "final" "NO"`" = "YES" ]
      then
         break
      fi

      IFS="
"
      for revname in ${revclonenames}
      do
         IFS="${DEFAULT_IFS}"

         srcdir="`stash_of_repository "${REPOS_DIR}" "${revname}"`/.bootstrap/${name}.build"

         if [ -d "${srcdir}" ]
         then
            inherit_files "${dstdir}" "${srcdir}"
            if [ "`read_build_setting "${name}" "final" "NO"`" = "YES" ]
            then
               break
            fi
         fi

         if [ "${revname}" = "${name}" ]
         then
            break
         fi

      done

      if [ ${has_overrides} -eq 0 ]
      then
         override_files "${dstdir}" "${BOOTSTRAP_DIR}.auto/overrides"
      fi
   done

   IFS="${DEFAULT_IFS}"
}


bootstrap_auto_final()
{
   [ -d "${BOOTSTRAP_DIR}.auto" ] || internal_fail "${BOOTSTRAP_DIR}.auto does not exists"

   log_fluff "Creating ${C_MAGENTA}${C_BOLD}build_order${C_VERBOSE} from repositories"

   if [ -f "${BOOTSTRAP_DIR}.auto/build_order" ]
   then
      log_fluff "build_order already exists"
      return
   fi

   #
   # add stuff from bootstrap folder
   # don't copy config if exists (it could be malicious)
   #
   # __parse_expanded_clone
   local name
   local url
   local branch
   local scm
   local tag
   local clone
   local order
   local clones

   clones="`read_root_setting "repositories"`"
   if [ -z "${clones}" ]
   then
      log_fluff "There is apparently nothing to build."
      return
   fi

   order=""

   IFS="
"
   for clone in ${clones}
   do
      IFS="${DEFAULT_IFS}"

      parse_clone "${clone}"
      order="`add_line "${order}" "${name}"`"
   done

   IFS="${DEFAULT_IFS}"

   redirect_exekutor "${BOOTSTRAP_DIR}.auto/build_order" echo "${order}"

   bootstrap_create_build_folders
}


auto_update_initialize()
{
   [ -z "${MULLE_BOOTSTRAP_LOGGING_SH}" ] && . mulle-bootstrap-logging.sh

   log_fluff ":auto_update_initialize:"

   MERGABLE_SETTINGS='brews
tarballs
repositories
'

   NON_MERGABLE_SETTINGS='embedded_repositories
version
'
   [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
   [ -z "${MULLE_BOOTSTRAP_COPY_SH}" ] && . mulle-bootstrap-copy.sh
   :
}

auto_update_initialize
