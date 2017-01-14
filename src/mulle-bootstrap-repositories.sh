#! /bin/sh
#
#   Copyright (c) 2016 Nat! - Mulle kybernetiK
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

MULLE_BOOTSTRAP_REPOSITORIES_SH="included"



# ####################################################################
#                       repository file
# ####################################################################
#

# deal with stuff like
# foo
# https://www./foo.git
# host:foo
#
canonical_clone_name()
{
   local  url

   url="$1"
   # cut off scheme part
   case "$url" in
      *:*)
         url="`echo "$@" | sed 's/^\(.*\):\(.*\)/\2/'`"
         ;;
   esac

   extension_less_basename "$url"
}


count_clone_components()
{
   echo "$@" | tr ';' '\012' | wc -l | awk '{ print $1 }'
}


url_from_clone()
{
   echo "$@" | cut '-d;' -f 1
}


_name_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 2
}


_branch_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 3
}


_scm_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 4
}


_tag_part_from_clone()
{
   echo "$@" | cut -s '-d;' -f 4
}



canonical_name_from_clone()
{
   local url
   local name
   local branch

   url="`url_from_clone "$@"`"
   name="`_name_part_from_clone "$@"`"

   if [ ! -z "${name}" -a "${name}" != "${url}" ]
   then
      canonical_clone_name "${name}"
      return
   fi

   canonical_clone_name "${url}"
}


branch_from_clone()
{
   local count

   count="`count_clone_components "$@"`"
   if [ "$count" -ge 3 ]
   then
      _branch_part_from_clone "$@"
   fi
}


scm_from_clone()
{
   local count

   count="`count_clone_components "$@"`"
   if [ "$count" -ge 4 ]
   then
      _scm_part_from_clone "$@"
   fi
}


tag_from_clone()
{
   local count

   count="`count_clone_components "$@"`"
   if [ "$count" -ge 5 ]
   then
      _tag_part_from_clone "$@"
   fi
}



embedded_repository_subdir_from_file()
{
   local path

   path="$1"

   [ -z "${path}" ] && internal_fail "Empty parameter"

   head -1 "${path}"
}


embedded_repository_subdir_in_repos()
{
   local reposdir
   local filename

   reposdir="$1"
   filename="$2"

   [ -z "${filename}" ] && internal_fail "Empty parameter"

   local relpath

   relpath="${reposdir}/.bootstrap_embedded/${filename}"
   if [ -f "${relpath}" ]
   then
      embedded_repository_subdir_from_file "${relpath}"
   fi
}


embedded_repository_url_in_repos()
{
   local reposdir
   local filename

   reposdir="$1"
   filename="$2"

   local url
   local relpath

   relpath="${reposdir}/.bootstrap_embedded/${filename}"
   if [ -f "${relpath}" ]
   then
      #
      # if only one line present, will retrieve that
      #
      tail -1 "${relpath}"
   fi
}

#
# search by url, may actually not exist though
# reposdir must have the proper dstprefix set
#
find_embedded_repository_subdir_in_repos()
{
   local reposdir
   local url

   reposdir="$1"
   url="$2"

   local filename

   IFS="
"
   for i in `fgrep -l -x "${url}" "${reposdir}/.bootstrap_embedded/"* 2> /dev/null`
   do
      IFS="${DEFAULT_IFS}"

      #
      # ensure that it's the URL that matched
      #
      match_url="`tail -1 "${i}"`"
      if [ "${match_url}" = "${url}" ]
      then
         embedded_repository_subdir_from_file "${i}"
         return
      fi
   done

   IFS="${DEFAULT_IFS}"
}


#
# look through embedded repositories
# reposdir must have the proper dstprefix set
# used by clean, don't need deeply embedded repos
#
embedded_repository_directories_from_repos()
{
   local reposdir
   local dstprefix

   reposdir="$1"
   dstprefix="$2"

   [ -z "${reposdir}" ] && internal_fail "repos is empty"

   local filename
   local embedded

   IFS="
"
   for filename in `ls -1 "${reposdir}/.bootstrap_embedded/" 2> /dev/null`
   do
      IFS="${DEFAULT_IFS}"

      embedded="`embedded_repository_subdir_in_repos "${reposdir}" "${filename}"`"
      if [ ! -z "${embedded}" ]
      then
         embedded="${dstprefix}${embedded}"
         if [ -d "${embedded}" ]
         then
            echo "${embedded}"
         fi
      fi
   done

   IFS="${DEFAULT_IFS}"
}


repository_directories_from_repos()
{
   local reposdir

   reposdir="$1"

   local filename

   IFS="
"
   for filename in `ls -1 "${reposdir}" 2> /dev/null`
   do
      echo "${reposdir}/$filename"
   done

   IFS="${DEFAULT_IFS}"
}


# dstprefix
all_repository_directories_from_repos()
{
   local reposdir
   local dstprefix

   reposdir="$1"
   dstprefix="$2"

   repository_directories_from_repos "${reposdir}"
   embedded_repository_directories_from_repos "${reposdir}" "${dstprefix}"
}


# this sets valuse to variables that should be declared
# in the caller!
#
#   # __parse_expanded_clone()
#   local name
#   local url
#   local branch
#   local scm
#   local tag
#
__parse_expanded_clone()
{
   local clone

   clone="${1}"

   name="`canonical_name_from_clone "${clone}"`"
   url="`url_from_clone "${clone}"`"
   branch="`branch_from_clone "${clone}"`"
   scm="`scm_from_clone "${clone}"`"
   tag="`tag_from_clone "${clone}"`"

   case "${name}" in
      /*|~*|..*|.*)
         fail "Destination \"${name}\" of ${1} looks fishy"
      ;;
   esac
}


# this sets valuse to variables that should be declared
# in the caller!
#
#   # __parse_clone()
#   local name
#   local url
#   local branch
#   local scm
#   local tag
#
__parse_clone()
{
   local clone

   clone="`expanded_variables "${1}"`"

   __parse_expanded_clone "${clone}"
}


# this sets values to variables that should be declared
# in the caller!
#
#   # __parse_embedded_clone
#   local name
#   local url
#   local branch
#   local scm
#   local tag
#   local subdir
#
__parse_embedded_clone()
{
   local clone

   clone="`expanded_variables "${1}"`"

   __parse_expanded_clone "${clone}"

   subdir="`_name_part_from_clone "${clone}"`"
   subdir="`simplify_path "${subdir}"`"

   case "${subdir}" in
      /*|~*|..*|.*)
         fail "Destination directory \"${subdir}\" of repository ${name} looks fishy"
      ;;

      "")
         subdir="${name}"
      ;;
   esac
}


ensure_clones_directory()
{
   local reposdir

   reposdir="$1"
   if [ ! -d "${reposdir}" ]
   then
      if [ "${COMMAND}" = "update" ]
      then
         fail "install first before upgrading"
      fi
      mkdir_if_missing "${reposdir}"
   fi
}


mulle_repositories_inititalize()
{
  [ -z "${MULLE_BOOTSTRAP_BUILD_ENVIRONMENT_SH}" ] && . mulle-bootstrap-build-environment.sh
  [ -z "${MULLE_BOOTSTRAP_SETTINGS_SH}" ] && . mulle-bootstrap-settings.sh
  [ -z "${MULLE_BOOTSTRAP_FUNCTIONS_SH}" ] && . mulle-bootstrap-functions.sh
}

mulle_repositories_inititalize
