set(JK_REF "bf45ec540c0de61eec91e5b50e1bec541b7fef8b")
set(JK_SHA512 "1cebe814aacf1ea3ac299583d6b0af3ea0e87496b4c51e70a1dd4a72906f15958589e0532e188c80234a9b6901b7674bcea66c7c517b86afb4d71d151f8f42d3")

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
