# mulle-dispense

🚰 Copy build products and reorganize them

![Last version](https://img.shields.io/github/tag/mulle-sde/mulle-dispense.svg)

... for Linux, OS X, FreeBSD, Windows


After having build something with your favorite build tool like `make`,
this tool will copy the build results to a destination folder.

Essentially, `mulle-dispense` is a shortcut for:

```
cd build
cp -Rp include share lib bin "${DEPENDENCY_DIR}"
```

But it is a bit more clever than that...

Headers can be reorganized to fit a canonical "subfolder for every library"
scheme, if so desired.


Executable          | Description
--------------------|--------------------------------
`mulle-dispense`    | Copy and reorganize build products


## Install

See [mulle-sde-developer](//github.com/mulle-sde/mulle-sde-developer) how
to install mulle-sde.

> If you want to do it manually, install mulle-bashfunctions fi


## GitHub and Mulle kybernetiK

The development is done on
[Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-dispense/master).
Releases and bug-tracking are on [GitHub](https://github.com/{{PUBLISHER}}/mulle-dispense).
