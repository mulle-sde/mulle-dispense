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
setup_test_dirs()
{
   mkdir -p a/.bootstrap
   mkdir -p b/test
}


setup_test_case1()
{
   echo "b;b" > a/.bootstrap/embedded_repositories
   mulle-bootstrap --version > a/.bootstrap/version
}



test_a()
{
   cd a || exit 1

   run_mulle_bootstrap "$@" -y -f fetch --embedded-symlinks || exit 1

   result="`cat .bootstrap.auto/embedded_repositories`"
   [ "b;b;master;;git" != "${result}" ] && fail ".bootstrap.auto/embedded_repositories ($result)"

   [ ! -e "b" ] && fail "b not created ($result)"

   result="`head -1 .bootstrap.repos/.embedded/b`"
   [ "b;b;master;;symlink" != "${result}" ] && fail "($result)"

   :
}

MULLE_BOOTSTRAP_LOCAL_PATH="`pwd -P`"
export MULLE_BOOTSTRAP_LOCAL_PATH

#
# not that much of a test
#
clear_test_dirs a b
setup_test_dirs
setup_test_case1
test_a "$@"
clear_test_dirs a b

echo "succeeded" >&2

