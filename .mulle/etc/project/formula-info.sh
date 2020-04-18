# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-dispense"      # your project/repository name
DESC=" 🚰 Copy build products and reorganize them "
LANGUAGE="bash"                # c,cpp, objc, bash ...
# NAME="${PROJECT}"        # formula filename without .rb extension

DEPENDENCIES='${MULLE_NAT_TAP}mulle-bashfunctions
'

DEBIAN_DEPENDENCIES="mulle-bashfunctions (>= 3.1.0)"

