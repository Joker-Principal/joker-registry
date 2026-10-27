set(JK_REF "1db4048c6e94bbc8f65ff1dafc68032c64b83e39")
set(JK_SHA512 "859a2b4de8d679ba70aebe3d0cde9d25b420c806cd0b209fd7defa5f18675c6e859eb9aca2ffd834706b377099a71f02c84512ae9ee44c3b1042aaec987b5004")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/jk
    REF "${JK_REF}"
    SHA512 "${JK_SHA512}"
    HEAD_REF master
)

set(JK_CXX_STANDARD "20")
if("cxx23" IN_LIST FEATURES)
    set(JK_CXX_STANDARD "23")
endif()

# jk 自己 include(CTest) 并把 BUILD_TESTING 默认成 ON ⇒ 显式关掉。
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
        -DJK_BUILD_TESTING=OFF
        -DJK_CXX_STANDARD=${JK_CXX_STANDARD}
)

vcpkg_cmake_install()

# jk 把包配置装在 share/jk/cmake（不是 share/jk）。
vcpkg_cmake_config_fixup(PACKAGE_NAME jk CONFIG_PATH "share/jk/cmake")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
