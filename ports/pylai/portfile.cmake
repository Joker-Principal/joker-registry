set(PYLAI_REF "cd9f342ca16f9a4a4b1d3090dce5f3baf0f8b4c7")
set(PYLAI_SHA512 "2e8e448752441c13f0458ad336f666dc5941e41fe1806cbf1404d28641bf365b26d57f1761da80ed243a273cdd2dc8822df12f0b47538d5a49a05f6198cd1773")

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
