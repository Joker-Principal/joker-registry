set(JK_REF "07fbea2f4c2a18bef141e3ec586bf2e53eb14f3e")
set(JK_SHA512 "acb762e89a76822e5cc1f99511cb8546011d5e58cb36a0e1750f121d439de8ffad0d3388dcdeaa5c6e9e0f8126dcd642d4d43791618db1d56ee9d7f4805867bb")

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
