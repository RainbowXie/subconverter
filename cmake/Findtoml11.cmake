find_package(PkgConfig QUIET)

if(PKG_CONFIG_FOUND)
    pkg_check_modules(TOML11 QUIET toml11)
endif()

if(TOML11_FOUND)
    set(TOML11_INCLUDE_DIRS ${TOML11_INCLUDE_DIRS})
else()
    find_path(TOML11_INCLUDE_DIRS
        NAMES toml.hpp toml11/toml.hpp
        PATH_SUFFIXES include toml11
    )
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(toml11
    REQUIRED_VARS TOML11_INCLUDE_DIRS
)

mark_as_advanced(TOML11_INCLUDE_DIRS)
