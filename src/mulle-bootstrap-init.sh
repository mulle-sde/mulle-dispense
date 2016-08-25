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

. mulle-bootstrap-local-environment.sh

#
# this script creates a .bootstrap folder with some
# demo files.
#
if [ "$1" = "-h" -o "$1" = "--help" ]
then
   echo "usage:
  mulle_bootstrap init" >&2
   exit 1
fi

BOOTSTRAP_SUBDIR=.bootstrap


CREATE_DEFAULT_FILES="`read_config_setting "create_default_files" "YES"`"
CREATE_EXAMPLE_FILES="`read_config_setting "create_example_files" "NO"`"


if [ -d "${BOOTSTRAP_SUBDIR}" ]
then
   log_warning "\"${BOOTSTRAP_SUBDIR}\" already exists"
   exit 1
fi


main()
{
   project=""
   for i in *.xcodeproj/project.pbxproj
   do
      if [ -f "$i" ]
      then
        if [ "$project" != "" ]
        then
           fail "more than one xcodeproj found, cant' deal with it"
        fi
        project="$i"
      fi
   done


   log_fluff "Create \"${BOOTSTRAP_SUBDIR}\""
   mkdir_if_missing "${BOOTSTRAP_SUBDIR}"

   if [ "${CREATE_DEFAULT_FILES}" = "YES" ]
   then
      log_fluff "Create default files"


#cat <<EOF > "${BOOTSTRAP_SUBDIR}/pips"
# add projects that should be installed by pip
# try to avoid it, since it needs sudo (uncool)
# mod-pbxproj
#EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/repositories"
#
# Add repository URLs to this file.
#
# mulle-bootstrap [fetch] will download these into "${CLONES_SUBDIR}"
# mulle-bootstrap [build] will then build them into "${DEPENDENCY_SUBDIR}"
#
# Each line consists of four fields, only the URL is necessary.
#
# URL;NAME;TAG;SCM
# ================
# ex. foo.com/bla.git;mybla;master;git
# ex. foo.com/bla.svn;;;svn
#
# Possible URLS for repositories:
#
# https://www.mulle-kybernetik.com/repositories/MulleScion
# git@github.com:mulle-nat/MulleScion.git
# ../MulleScion
# /Volumes/Source/srcM/MulleScion
#
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/embedded_repositories"
#
# Add repository URLs to this file.
#
# mulle-bootstrap [fetch] will download these into your project root
# mulle-bootstrap [build] will NOT build them
#
# Each line consists of four fields, only the URL is necessary.
#
# URL;NAME;TAG;SCM
# ================
# ex. foo.com/bla.git;mybla;master;git
# ex. foo.com/bla.svn;;;svn
#
# Possible URLS for repositories:
#
# https://www.mulle-kybernetik.com/repositories/MulleScion
# git@github.com:mulle-nat/MulleScion.git
# ../MulleScion
# /Volumes/Source/srcM/MulleScion
#
EOF
      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/brews"
#
# Add homebrew packages to this file (https://brew.sh/)
#
# mulle-bootstrap [fetch] will install those into "${ADDICTION_SUBDIR}"
#
# e.g.
# zlib
#
EOF

   fi

   if [ "${CREATE_EXAMPLE_FILES}" = "YES" ]
   then
      log_fluff "Create example repository settings"

      mkdir_if_missing "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/bin"

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/Release.map"
# map configuration Release in project MulleScion to DebugRelease
# leave commented out or delete file for no mapping
# DebugRelease
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/project"
# Specify a xcodeproj to compile in project MulleScion instead of the default
# leave commented out or delete file for default project
# mulle-scion
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/scheme"
# Specify a scheme to compile in project MulleScion instead of the default
# Might bite itself with TARGET, so only specify one.
# leave commented out or delete file for default scheme
# mulle-scion
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/target"
# Specify a target to compile in project MulleScion instead of the default.
# Might bite itself with SCHEME, so only specify one.
# leave commented out or delete file for default scheme
# mulle-scion
EOF

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/bin/post-install.sh"
# Run some commands after installing project MulleScion
# leave commented out or delete file for no action
# chmod 755 ${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-install.sh
# to make it work
# echo "1848"
EOF
#chmod 755 "${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-install.sh"

      exekutor cat <<EOF > "${BOOTSTRAP_SUBDIR}/settings/MulleScion.example/bin/post-update.sh"
# Run some commands after upgrading project MulleScion
# leave commented out or delete file for no action
# chmod 755 ${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-update.sh
# to make it work
# echo "1848"
EOF
#chmod 755 "${BOOTSTRAP_SUBDIR}/MulleScion.example/bin/post-upgrade.sh"

  fi

  log_info "\"${BOOTSTRAP_SUBDIR}\" folder has been set up."

  local open

  open="`read_config_setting "open_repositories_file" "ASK"`"

  if [ "${open}" = "ASK" ]
  then
    user_say_yes "Edit the ${C_MAGENTA}${C_BOLD}repositories${C_RESET_BOLD} file now ?"
    if [ $? -eq 0 ]
    then
       open="YES"
    fi
  fi

  if [ "${open}" = "YES" ]
  then
     local editor

     editor="`read_config_setting "editor" "${EDITOR:-vi}"`"
     exekutor $editor "${BOOTSTRAP_SUBDIR}/repositories"
  fi
}

main "$@"