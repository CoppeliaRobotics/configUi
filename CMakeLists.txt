cmake_minimum_required(VERSION 3.12)
project(configUi-2)

if(NOT COPPELIASIM_INCLUDE_DIR)
    if(DEFINED ENV{COPPELIASIM_ROOT_DIR})
        set(COPPELIASIM_INCLUDE_DIR $ENV{COPPELIASIM_ROOT_DIR}/programming/include)
    else()
        set(COPPELIASIM_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../include)
    endif()
endif()
find_package(CoppeliaSim 4.5.1.7 REQUIRED)

coppeliasim_add_lua("configUi-2.lua")
coppeliasim_add_resource_directory(qml)
