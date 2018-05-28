# mulle-dispense, 🚰 Copy build products and reorganize them

![Last version](https://img.shields.io/github/tag/{{PUBLISHER}}/mulle-dispense.svg)

... for Linux, OS X, FreeBSD, Windows


After having build something with your favorite build tool like `make`,
this tool will copy the results to a destination folder.

Headers can be reorganized to fit a canonical "subfolder for every library"
scheme, if so desired.

Executable          | Description
--------------------|--------------------------------
`mulle-dispense`    | Copy and reorganize build products


## Install

See [mulle-sde-developer](//github.com/mulle-sde/mulle-sde-developer) how
to install mulle-sde.


## What mulle-dispense does

Essentially, `mulle-dispense` is a shortcut for:

```
cd build
cp -Ra include share lib bin "${DEPENDENCY_DIR}"
```

But mulle-dispense is a bit more clever than that.


## GitHub and Mulle kybernetiK

The development is done on
[Mulle kybernetiK](https://www.mulle-kybernetik.com/software/git/mulle-dispense/master).
Releases and bug-tracking are on [GitHub](https://github.com/{{PUBLISHER}}/mulle-dispense).
