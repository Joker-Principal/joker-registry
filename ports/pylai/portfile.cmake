set(PYLAI_REF "da535ceb8f3e8b9c52e033d17fffe56f57cf203f")
set(PYLAI_SHA512 "910fb0f5168c005fe0c6863d33ddadc34d14a0e397c4d16ced8b5a12d9c6ef8731e9bf30323bdc577c36db3474f4bd5e963d3f7b923f9280013b3d971bd6d723")

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
