set(JK_REF "438f8b20eb1325a08cbbf4de9111f7d1bff0cac4")
set(JK_SHA512 "8daf4ef98131d07e3fe8b14258ef78dd3e6850273cd73009c5498206da118fa48e652f3430e285d7d7c1dc1d2d85d68e2cb20fe8ef84780b7e1b93eb76780c63")

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
