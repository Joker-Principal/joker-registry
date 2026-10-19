set(PYLAI_REF "4b871d62d6c929400ea1da04e972425edb9f78ed")
set(PYLAI_SHA512 "453c92994e49164ddde4b446bfcb8531e0c98836110f5950a3f8883fea0898ced81db1b87c6ed8f326f5b469caaa2a41d2ad3e86d6d0468d1d72a8220e6f1ed6")

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
