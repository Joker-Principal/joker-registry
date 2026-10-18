# pylai 暂无 release / tag ⇒ 钉 commit（推了新版本就把 REF + SHA512 一起换掉）。
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/pylai
    REF 2c35e6d41a6b51c5de1e9bd3bb7db409fe1bb7d1
    SHA512 2dfa8ce6bd2fc70a4c2d6dd8dccb57f6fc21f2abc2194772700c0260d318f08d5e9f3a4084cd3d9122fdfd1752364a256bdcc95230216494fd9ee382675d00bb
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
