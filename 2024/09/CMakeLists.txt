cmake_minimum_required(VERSION 3.20)

# Project Name and C++ Version
project(Aoc2024 VERSION 1.0 LANGUAGES CXX)

# Enforce C++23 standard
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Source files directory
set(SRC_DIR "src")

# Gather all source files
file(GLOB_RECURSE SOURCES "${SRC_DIR}/*.cpp")

if(NOT DEFINED DEBUG_RENDER)
    set(DEBUG_RENDER 0)
endif()
add_compile_definitions(DEBUG_RENDER=${DEBUG_RENDER})

find_package(GTest REQUIRED)

# Create the executable
add_executable(${PROJECT_NAME} ${SOURCES})

target_link_libraries(${PROJECT_NAME} gtest::gtest)

# Set include directories
target_include_directories(${PROJECT_NAME} PUBLIC ${SRC_DIR})
target_compile_definitions(Aoc2024 PUBLIC)
