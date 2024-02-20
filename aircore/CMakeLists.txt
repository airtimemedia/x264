# Copyright Airtime Media 2016

project(x264)

find_program(NASM nasm)
if(NASM STREQUAL "NASM-NOTFOUND")
  message(FATAL_ERROR "'nasm' not found. Please install. (${NASM})")
endif()

if((NOT ${at_target_os} MATCHES osx) AND NOT (${at_target_os} MATCHES linux))
  message(FATAL_ERROR "x264 not supported on this platform")
endif()

if(APPLE AND CMAKE_OSX_ARCHITECTURES)
  set(ARCHS ${CMAKE_OSX_ARCHITECTURES})
else()
  set(ARCHS ${at_target_arch})
endif()

set(x264_lib_files "")
set(x264_binary_base_dir "${PROJECT_BINARY_DIR}/build")

# serialize the calls to configure by chaining dependencies since configuring
# multiple archs in parallel seems to cause issues (at least with Xcode)
set(last_configure_target "")

foreach(ARCH ${ARCHS})
  set(x264_binary_dir "${x264_binary_base_dir}/${ARCH}")
  set(x264_makefile "${x264_binary_dir}/Makefile")

  set(libx264_arch_file "${x264_binary_dir}/libx264.a")

  file(MAKE_DIRECTORY "${x264_binary_dir}")

  # configure
  add_custom_command(
    OUTPUT ${x264_makefile}
    COMMAND "${PROJECT_SOURCE_DIR}/run_config.sh"
    ARGS "${at_media_deps_dir}/x264" "${AT_CMAKE_C_COMPILER} ${AT_CMAKE_C_COMPILER_ARG1}" "${CMAKE_C_FLAGS_RELEASE}" "${at_target_os}" "${ARCH}" "${at_ccache}" "${CMAKE_AR}" "${CMAKE_RANLIB}" "${CMAKE_SHARED_LINKER_FLAGS}" "${NASM}"
    WORKING_DIRECTORY ${x264_binary_dir}
    DEPENDS ${PROJECT_SOURCE_DIR}/run_config.sh ${last_configure_target}
    VERBATIM
  )

  add_custom_target(x264_configure_${ARCH}
    DEPENDS ${x264_makefile}
  )
  set(last_configure_target x264_configure_${ARCH})

  # make
  file(GLOB_RECURSE x264_sources src *.c *.h *.s)
  add_custom_command(
    OUTPUT ${libx264_arch_file}
    COMMAND make # V=1 # add V=1 for verbose output
    DEPENDS x264_configure_${ARCH} ${x264_sources}
    WORKING_DIRECTORY ${x264_binary_dir}
  )

  list(APPEND libx264_lib_files ${libx264_arch_file})

endforeach()

add_custom_target(x264_build
  DEPENDS ${libx264_lib_files}
  SOURCES ${x264_sources}
)

list(LENGTH CMAKE_OSX_ARCHITECTURES num_archs)
if (APPLE AND num_archs GREATER 1)
  set(x264_universal_binary_dir "${x264_binary_base_dir}/universal")
  file(MAKE_DIRECTORY "${x264_universal_binary_dir}")

  set(libx264_file "${x264_universal_binary_dir}/libx264.a")

  add_custom_command(TARGET x264_build POST_BUILD
    COMMAND lipo -output ${libx264_file} -create ${libx264_lib_files}
  )
else()
  set(libx264_file ${libx264_lib_files})
endif()

# NOTE: This doesn't seem to work with ninja and ExternalProject due to this bug:
# http://public.kitware.com/Bug/view.php?id=13574
add_library(libx264 STATIC IMPORTED GLOBAL)
set_target_properties(libx264
  PROPERTIES IMPORTED_LOCATION "${libx264_file}"
)
add_dependencies(libx264 x264_build)
