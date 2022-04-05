
# BringAuto Package Tracker

BringAuto package tracker based on [BringAuto Packager] and [CMake-lib]

## Usage

```
# Add package - download, cache and populate
BA_PACKAGE_LIBRARY(nlohmann-json v3.10.5 PLATFORM_STRING_MODE any_machine)
# Find package as described in the library manual 
FIND_PACKAGE(nlohmann_json 3.2.0 REQUIRED)
```

Full example: [example/]

## Requirements

- [CMake-lib] with STORAGE component enabled. One of the storage entry must points to this repo.
- Package repository that is complain with [BringAuto Packager] package repository structure.


## Macros

- `BA_PACKAGE_LIBRARY` downloads and init package build by [BringAuto Packager]
- `BA_PACKAGE_DEPS_IMPORTED` installs all imported linked dependencies for a given target


## FAQ

### Q: Package not found even if it exists in the remote repository

Make sure you choosed correct `PLATFORM_STRING_MODE`.

If package is not bound to the architecture or Linux distro this context info must be passed down by the `PLATFORM_STRING_MODE`.



[BringAuto Packager]: https://github.com/bringauto/packager
[CMake-lib]: https://github.com/cmakelib/cmakelib
[example/]: example/