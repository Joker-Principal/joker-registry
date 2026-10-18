set(JK_REF "34f947259548ad5668bd6a8d0b0846f22dd1c042")
set(JK_SHA512 "b9ce1db6e00f11f178e81b214d4cd2880e2dba2535ddb98b2f4669930f0354bd9785ab98a1cd51c08a2345b26561b84ae64e085165dbedb6eca922ef4e48afd3")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/jk
    REF "${JK_REF}"
    SHA512 "${JK_SHA512}"
    HEAD_REF master
)

# jk 自己 include(CTest) 并把 BUILD_TESTING 默认成 ON ⇒ 显式关掉。
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
        -DJK_BUILD_TESTING=OFF
)

vcpkg_cmake_install()

# jk 把包配置装在 share/jk/cmake（不是 share/jk）。
vcpkg_cmake_config_fixup(PACKAGE_NAME jk CONFIG_PATH "share/jk/cmake")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
