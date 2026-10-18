set(PYLAI_REF "267002bff0ab32870e6c1bc921788c99b35417d8")
set(PYLAI_SHA512 "efc897cac91bd0918a9fed15bd1b46b3ee7c2ae7be6d8f0066e867d5e4e18ac209c3c24f05a38b2e8b5a0f3b554f066162c62818ae8ad331c92e7086ca2a8b24")

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
