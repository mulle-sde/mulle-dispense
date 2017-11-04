cdispense_minimum_required (VERSION 3.0)

# use C, because otherwise a CXX compiler is required
project( mulle-dispense C)

#
# Primarily used for packaging on Linux
#
# Debian:
#
# ```
# mkdir package
# cd package
# cmake ..
# cpack -G DEB
# ```
#

execute_process( COMMAND ./mulle-dispense version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_DISPENSE_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_DISPENSE_VERSION is ${MULLE_DISPENSE_VERSION} according to mulle-dispense")


set( PROJECT_VERSION "${MULLE_DISPENSE_VERSION}")


set( SCRIPTS
mulle-dispense
)


if(MINGW)
   set( SCRIPTS
${SCRIPTS}
mulle-mingw-dispense
)

endif()


set( LIBRARY_SCRIPTS
src/mulle-dispense-copy.sh
src/mulle-dispense-mingw.sh
src/mulle-dispense-mv-force
)



INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")


#
# future: install into libexec/mulle-dispense/${MULLE_DISPENSE_VERSION}
#         allows multiple versions to co-exist (does it really ?)
#
INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-dispense")



######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.txt)
include( CPack)

