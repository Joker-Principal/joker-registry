vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/jk
    REF v2.1.0
    SHA512 74a9074682256287d5273730c125a96ad48fea742a2703e9e17c687a2c3e7a36fe4bef0c283e5e05efc57c282acb057ab38ec02b9fcbe384701dd705946ad250
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
