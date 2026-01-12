#  🚰 Copy build products and reorganize them 

... for Android, BSDs, Linux, macOS, SunOS, Windows (MinGW, WSL)

After having build something with your favorite build tool like `make`, this
tool will copy the build results to a destination folder. Essentially,
`mulle-dispense` is a shortcut for:

``` sh
cd build
cp -Rp include share lib bin "${DEPENDENCY_DIR}"
```

But headers can be reorganized to fit a canonical "subfolder for every library"
scheme. So `#include <zlib.h>` may become `#include <zlib/zlib.h>`.

| Release Version                                       | Release Notes
|-------------------------------------------------------|--------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/mulle-sde/mulle-dispense.svg)  | [RELEASENOTES](RELEASENOTES.md) |





# No usage








## Install

See [mulle-sde-developer](//github.com/mulle-sde/mulle-sde-developer) how to
install mulle-sde, which will also install mulle-dispense with required
dependencies.

The command to install only the latest mulle-dispense into
`/usr/local` (with **sudo**) is:

``` bash
curl -L 'https://github.com/mulle-sde/mulle-dispense/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-dispense-latest' && sudo ./bin/installer /usr/local
```



## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK


