cmake_minimum_required(VERSION 3.21)

project(iActions VERSION 0.6.8 LANGUAGES CXX)

# Required MinLL migration profile; apply before SDK/plugin/PCH targets.
if(MSVC)
    if(MSVC_VERSION LESS 1930 OR MSVC_VERSION GREATER_EQUAL 1950)
        message(FATAL_ERROR "Use VS2022 MSVC and a fresh build directory")
    endif()
    foreach(_configuration RELEASE RELWITHDEBINFO)
        string(REGEX REPLACE "(^|[ \t])[-/]O[12dsx]([ \t]|$)" "\\1\\2"
            CMAKE_CXX_FLAGS_${_configuration} "${CMAKE_CXX_FLAGS_${_configuration}}")
        string(REGEX REPLACE "(^|[ \t])[-/]Ob[0-3]([ \t]|$)" "\\1\\2"
            CMAKE_CXX_FLAGS_${_configuration} "${CMAKE_CXX_FLAGS_${_configuration}}")
        string(APPEND CMAKE_CXX_FLAGS_${_configuration} " /Od /Ob0")
    endforeach()
    set(CMAKE_CXX23_STANDARD_COMPILE_OPTION "/std:c++23preview")
    set(CMAKE_CXX23_EXTENSION_COMPILE_OPTION "/std:c++23preview")
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
option(IACTIONS_COPY_OUTPUT "Copy the built DLL to repository iActions/SKSE/Plugins" ON)
set(OUTPUT_FOLDER "${CMAKE_CURRENT_SOURCE_DIR}/../../iActions")

include(FetchContent)
set(BUILD_TESTS OFF CACHE BOOL "CommonLib tests" FORCE)
set(ENABLE_SKYRIM_SE ON CACHE BOOL "Skyrim SE support" FORCE)
set(ENABLE_SKYRIM_AE ON CACHE BOOL "Skyrim AE support" FORCE)
set(ENABLE_SKYRIM_VR ON CACHE BOOL "Skyrim VR support" FORCE)
set(COMMONLIB_PREBUILT OFF CACHE BOOL "Source-build CommonLib" FORCE)
set(COMMONLIB_PREBUILT_DIR "" CACHE PATH "No prebuilt CommonLib" FORCE)
set(_minll_commit "550cc4fb9114649dcf526d1f3d73d710c5d7003b")
FetchContent_Declare(CommonLibSSE
    GIT_REPOSITORY https://github.com/MinLL/CommonLibVR.git
    GIT_TAG ${_minll_commit}
    GIT_SUBMODULES extern/openvr)
FetchContent_MakeAvailable(CommonLibSSE)

get_target_property(_imported CommonLibSSE IMPORTED)
if(_imported)
    message(FATAL_ERROR "iActions requires source-built CommonLib")
endif()
get_target_property(_minll_source CommonLibSSE SOURCE_DIR)
find_package(Git REQUIRED)
execute_process(COMMAND "${GIT_EXECUTABLE}" -C "${_minll_source}" rev-parse HEAD
    RESULT_VARIABLE _rev_result OUTPUT_VARIABLE _rev OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT _rev_result EQUAL 0 OR NOT _rev STREQUAL _minll_commit)
    message(FATAL_ERROR "Unexpected CommonLib revision: ${_rev}")
endif()
execute_process(COMMAND "${GIT_EXECUTABLE}" -C "${_minll_source}" status --porcelain --untracked-files=all
    RESULT_VARIABLE _status_result OUTPUT_VARIABLE _status OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT _status_result EQUAL 0 OR NOT _status STREQUAL "")
    message(FATAL_ERROR "CommonLib checkout must be clean: ${_status}")
endif()
file(STRINGS "${_minll_source}/LICENSE" _license LIMIT_COUNT 1)
if(NOT _license STREQUAL "MIT License")
    message(FATAL_ERROR "Unexpected CommonLib license")
endif()
message(STATUS "CommonLib provenance: MinLL/CommonLibVR ${_rev}, MIT, source-built")

# The pinned cross-VR wrappers select 0x97 flat / 0x98 VR.
file(READ "${_minll_source}/include/RE/T/TESObjectREFR.h" _header)
string(REPLACE "\r\n" "\n" _header "${_header}")
string(SHA256 _original_sha "${_header}")
if(NOT _original_sha STREQUAL "98a8a1cb24f51b893b4343c4c552e363d9bc90ee7a611c05f7719c2479bec2b6")
    message(FATAL_ERROR "TESObjectREFR.h changed; re-audit the cross-VR wrapper ABI")
endif()
include("${_minll_source}/cmake/CommonLibSSE.cmake")

function(add_skse_plugin PLUGIN_NAME)
    add_commonlibsse_plugin(${PLUGIN_NAME} USE_ADDRESS_LIBRARY SOURCES ${ARGN})
    target_compile_features(${PLUGIN_NAME} PRIVATE cxx_std_23)
    target_include_directories(${PLUGIN_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..)
    target_precompile_headers(${PLUGIN_NAME} PRIVATE ../PCH.h)

    if(IACTIONS_COPY_OUTPUT)
        set(DLL_FOLDER "${OUTPUT_FOLDER}/SKSE/Plugins")
        message(STATUS "${PLUGIN_NAME} output: ${DLL_FOLDER}")
        add_custom_command(
            TARGET "${PLUGIN_NAME}"
            POST_BUILD
            COMMAND "${CMAKE_COMMAND}" -E make_directory "${DLL_FOLDER}"
            COMMAND "${CMAKE_COMMAND}" -E copy_if_different "$<TARGET_FILE:${PLUGIN_NAME}>" "${DLL_FOLDER}/$<TARGET_FILE_NAME:${PLUGIN_NAME}>"
            VERBATIM
        )
    endif()
endfunction()

add_skse_plugin("iActions" "../src/main.iactions.cpp")

add_executable(iActions_saved_parent_abi EXCLUDE_FROM_ALL "../tests/saved_parent_abi.cpp")
target_link_libraries(iActions_saved_parent_abi PRIVATE CommonLibSSE::CommonLibSSE)
target_compile_definitions(iActions_saved_parent_abi PRIVATE ENABLE_COMMONLIBSSE_TESTING=1)
target_precompile_headers(iActions_saved_parent_abi PRIVATE "${_minll_source}/include/SKSE/Impl/PCH.h")
