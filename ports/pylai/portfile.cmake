set(PYLAI_REF "bce11dbc9520c8a831c7846f27219fc4e9949e2d")
set(PYLAI_SHA512 "491ab817197af655580e07996329cec40e01bf60d4ca4edb746b9cacfabd335b51aca6aa71ea0ede8e4a1403a547086de44019a809b4f9affaa7ff135b1a775b")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/pylai
    REF "${PYLAI_REF}"
    SHA512 "${PYLAI_SHA512}"
    HEAD_REF master
)

# 端口构建不是开发环境：测试一律不编。
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
        -DPYLAI_BUILD_TESTS=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME pylai CONFIG_PATH "lib/cmake/pylai")

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)
