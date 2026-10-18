# pylai 暂无 release / tag ⇒ 钉 commit（推了新版本就把 REF + SHA512 一起换掉）。
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/pylai
    REF 52ec2b0e83ff1eec056e8455234f0edb1ae99c4e
    SHA512 035c0f3caf97e7666b7b31f5747bb9a1640c08da5c962511eca3ff225e7420b286e39c498d46f4680557ec440a832dbab7b623baa8abc44a9140aeb9d1ab063e
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
