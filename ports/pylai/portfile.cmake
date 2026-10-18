# pylai 暂无 release / tag ⇒ 钉 commit（推了新版本就把 REF + SHA512 一起换掉）。
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Joker-Principal/pylai
    REF 55dad0c23a6d7831910e4c6b61c03f69cc5862eb
    SHA512 868b823d0a480b74cfef8fef2778df91a8e340e5aef83fca66dc1a892cee0b6d0577628c1f19483fcc6f6afecb0e8e96c5838e3eed0b9b102986e494fc96251f
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
