# pylai 暂无 release / tag ⇒ 钉 commit（推了新版本就把 REF + SHA512 一起换掉）。
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/pylai
    REF 25b63bdd3fe9d938d205f21a6b943c6290e88207
    SHA512 4236f5bd2cff79a78f29d6cd7630d964eed71b5001874e292f34abaa2eca461de03a5c191ec4ce45040c8afbc356a7f9f36a4c20bab2985cb3c376a626e3acf1
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
