#! /bin/sh

clear_test_dirs()
{
   local i

   for i in "$@"
   do
      if [ -d "$i" ]
      then
         chmod -R a+wX "$i"
         rm -rf "$i"
      fi
   done
}


fail()
{
   echo "failed" "$@" >&2
   exit 1
}


run_mulle_bootstrap()
{
   echo "####################################" >&2
   echo mulle-bootstrap "$@"  >&2
   echo "####################################" >&2

   mulle-bootstrap "$@" || fail "mulle-bootstrap failed"
}


#
#
#
setup_test_case()
{
   mkdir -p a && ( cd a ; mulle-bootstrap -s init -n ) &&
   mkdir -p b && ( cd b ; mulle-bootstrap -s init -n ) &&
   mkdir -p b/bee &&
   mkdir -p c/cee &&

   echo '${B};b' > a/.bootstrap/repositories &&
   echo 'b'      > a/.bootstrap/B &&
   echo '${C};c' > b/.bootstrap/embedded_repositories &&
   echo 'c'      > b/.bootstrap/C
}



_test_1()
{
   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} -y -f fetch  || exit 1

   result="`cat .bootstrap.auto/repositories 2> /dev/null`"
   expect="b;b;master;;git"
   if [ "${expect}" != "${result}" ]
   then
      fail "($result)" >&2
   fi

   result="`cat .bootstrap.auto/embedded_repositories 2> /dev/null`"
   expect=""
   if [ "${expect}" != "${result}" ]
   then
      fail "($result)" >&2
   fi

   if [ ! -d b/bee ]
   then
      fail "(b/bee)" >&2
   fi

   if [ -d b/c/cee ]
   then
      fail "(b/c/cee) should not exist because b is symlinked" >&2
   fi
}


_test_2()
{
   run_mulle_bootstrap ${BOOTSTRAP_FLAGS} -y -f fetch --embedded-symlinks --follow-symlinks || exit 1

   result="`cat .bootstrap.auto/repositories 2> /dev/null`"
   expect="b;b;master;;git"
   if [ "${expect}" != "${result}" ]
   then
      fail "($result)" >&2
   fi

   result="`cat .bootstrap.auto/embedded_repositories 2> /dev/null`"
   expect=""
   if [ "${expect}" != "${result}" ]
   then
      fail "($result)" >&2
   fi

   if [ ! -d b/bee ]
   then
      fail "(b/bee)" >&2
   fi

   if [ ! -d b/c/cee ]
   then
      fail "(b/c/cee)" >&2
   fi
}



test_1()
{
   clear_test_dirs a b c &&
   setup_test_case &&


   (
      cd a &&
      _test_1 "$@"
   ) || exit 1
}


test_2()
{
   clear_test_dirs a b c &&
   setup_test_case &&

   (
      cd a &&
      _test_2 "$@"
   ) || exit 1
}

BOOTSTRAP_FLAGS="$@"

MULLE_BOOTSTRAP_LOCAL_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_LOCAL_PATH

#
# not that much of a test
#
test_1 &&
test_2 &&
echo "succeeded" >&2

clear_test_dirs a b c
