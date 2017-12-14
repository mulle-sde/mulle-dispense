#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


run_mulle_dispense()
{
   log_fluff "####################################"
   log_fluff ${MULLE_DISPENSE} ${MULLE_DISPENSE_FLAGS} "$@"
   log_fluff "####################################"

   exekutor ${MULLE_DISPENSE} ${MULLE_DISPENSE_FLAGS} "$@"
}


_setup_demo_build_dir()
{
   local directory="$1"

   [ -z "${PREFIX_PATH}" ]     && internal_fail "PREFIX_PATH" is empty
   [ -z "${HEADER_DIR_NAME}" ] && internal_fail "HEADER_DIR_NAME" is empty
   [ -z "${LIBRARY_DIR_NAME}" ] && internal_fail "LIBRARY_DIR_NAME" is empty
   [ -z "${LIBRARY_SUFFIXES}" ] && internal_fail "LIBRARY_DIR_NAME" is empty
   [ -z "${HEADER_SUFFIXES}" ]  && internal_fail "LIBRARY_DIR_NAME" is empty

   IFS=":"
   for prefix in ${PREFIX_PATH}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${HEADER_DIR_NAME}" ]
      then
         local includedir="${directory}${prefix}/${HEADER_DIR_NAME}"

         mkdir_if_missing "${includedir}"

         for suffix in ${HEADER_SUFFIXES}
         do
            redirect_exekutor "${includedir}/header${suffix}" echo "// ${includedir}"
         done
      fi

      if [ ! -z "${LIBRARY_DIR_NAME}" ]
      then
         local libdir="${directory}${prefix}/${LIBRARY_DIR_NAME}"

         mkdir_if_missing "${libdir}"

         local suffix

         for suffix in ${LIBRARY_SUFFIXES}
         do
            redirect_exekutor "${libdir}/${LIBRARY_PREFIX}library${suffix}" echo "// ${libdir}"
         done
      fi

      if [ ! -z "${RESOURCES_DIR_NAME}" ]
      then
         local resourcedir="${directory}${prefix}/${RESOURCES_DIR_NAME}"

         mkdir_if_missing "${resourcedir}"

         local suffix

         for suffix in ${LIBRARY_SUFFIXES}
         do
            redirect_exekutor "${libdir}/resource" echo "// ${libdir}"
         done
      fi

      if [ ! -z "${BIN_DIR_NAME}" ]
      then
         local bindir="${directory}${prefix}/${BIN_DIR_NAME}"

         mkdir_if_missing "${bindir}"

         if [ ! -z "${EXE_SUFFIXES}" ]
         then
            for suffix in ${EXE_SUFFIXES}
            do
               redirect_exekutor "${bindir}/executable${suffix}" echo "// ${bindir}"
            done
         else
            redirect_exekutor "${bindir}/executable" echo "// ${bindir}"
         fi
      fi

      if [ ! -z "${SBIN_DIR_NAME}" ]
      then
         local sbindir="${directory}${prefix}/${SBIN_DIR_NAME}"

         mkdir_if_missing "${sbindir}"

         if [ ! -z "${EXE_SUFFIXES}" ]
         then
            for suffix in ${EXE_SUFFIXES}
            do
               redirect_exekutor "${sbindir}/sys_executable${suffix}" echo "// ${sbindir}"
            done
         else
            redirect_exekutor "${sbindir}/sys_executable" echo "// ${sbindir}"
         fi
      fi
   done

   IFS="${DEFAULT_IFS}"
}


setup_demo_srcdir_1()
{
   (
      set -e
      _setup_demo_build_dir "$@"
   )
}


expect_content()
{
   local output="$1"
   local expect="$2"

   if [ ! -f "${output}" ]
   then
      if [ -z "${expect}" ]
      then
         return
      fi
      fail "Did not produce \"${output}\" as expected"
   else
      if [ -z "${expect}" ]
      then
         fail "Did produce \"${output}\" unexpectedly. Nothing was expected"
      fi
   fi

   local diffs

   diffs="`diff -b -B "${output}" - <<< "${expect}"`"
   if [ $? -ne 0 ]
   then
      log_error "Unexpected output generated"
      cat <<EOF >&2
----------------
Output: ($output)
----------------
`cat "${output}"`
----------------
Expected:
----------------
${expect}
----------------
Diff:
----------------
${diff}
----------------
EOF
      exit 1
   fi
}


main()
{
   MULLE_DISPENSE_FLAGS="$@"

   _options_mini_main "$@"

   local directory
   local dstdir
   local srcdir

   directory="`make_tmp_directory`" || exit 1
   directory="${directory:-/tmp/exekutor}"

   srcdir="${directory}/src"
   dstdir="${directory}/dst"

   setup_demo_srcdir_1 "${srcdir}"  || exit 1
   run_mulle_dispense copy "${srcdir}" "${dstdir}"

   case "${UNAME}" in
      mingw)
         expect_content "${dstdir}/include/header.h" "// ${srcdir}/usr/local/include"
         expect_content "${dstdir}/include/header.hpp" "// ${srcdir}/usr/local/include"
         expect_content "${dstdir}/include/header.inc" "// ${srcdir}/usr/local/include"

         expect_content "${dstdir}/bin/executable.exe" "// ${srcdir}/usr/local/bin"
         expect_content "${dstdir}/bin/executable.bat" "// ${srcdir}/usr/local/bin"

         expect_content "${dstdir}/lib/library.lib" "// ${srcdir}/usr/local/lib"
         expect_content "${dstdir}/lib/library.dll" "// ${srcdir}/usr/local/lib"
      ;;

      darwin)
         expect_content "${dstdir}/include/header.h" "// ${srcdir}/usr/local/include"
         expect_content "${dstdir}/include/header.hpp" "// ${srcdir}/usr/local/include"
         expect_content "${dstdir}/include/header.inc" "// ${srcdir}/usr/local/include"

         expect_content "${dstdir}/bin/executable" "// ${srcdir}/usr/local/bin"
         expect_content "${dstdir}/sbin/sys_executable" "// ${srcdir}/usr/local/sbin"

         expect_content "${dstdir}/lib/liblibrary.a" "// ${srcdir}/usr/local/lib"
         expect_content "${dstdir}/lib/liblibrary.dylib" "// ${srcdir}/usr/local/lib"
      ;;

      *)
         expect_content "${dstdir}/include/header.h" "// ${srcdir}/usr/local/include"
         expect_content "${dstdir}/include/header.hpp" "// ${srcdir}/usr/local/include"
         expect_content "${dstdir}/include/header.inc" "// ${srcdir}/usr/local/include"

         expect_content "${dstdir}/bin/executable" "// ${srcdir}/usr/local/bin"
         expect_content "${dstdir}/sbin/sys_executable" "// ${srcdir}/usr/local/bin"

         expect_content "${dstdir}/lib/liblibrary.a" "// ${srcdir}/usr/local/lib"
         expect_content "${dstdir}/lib/liblibrary.so" "// ${srcdir}/usr/local/lib"
      ;;
   esac

   log_info "----- ALL PASSED -----"

   rmdir_safer "${directory}"
}



init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

   MULLE_DISPENSE="${MULLE_DISPENSE:-${PWD}/../../mulle-dispense}"

   MULLE_DISPENSE_LIBEXEC_DIR="`${MULLE_DISPENSE} library-path`" || exit 1

   . "${MULLE_DISPENSE_LIBEXEC_DIR}/mulle-dispense-osspecific.sh" || exit 1
}



init "$@"
main "$@"

