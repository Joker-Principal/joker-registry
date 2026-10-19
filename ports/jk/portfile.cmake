set(JK_REF "d0c96e65bbecf44f1dcd327adac3966387685ea0")
set(JK_SHA512 "4c68f8e963918041a9a05df3d70853302298c9c38ddb56fa896af298f0862fdc89f855188aa8ccb9476ead48f07695a8f050947051e6db455f8f80b26542e020")

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
