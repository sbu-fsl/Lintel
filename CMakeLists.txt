#
# (c) Copyright 2008, Hewlett-Packard Development Company, LP
#
#  See the file named COPYING for license details
#
# Main cmake control file

# ELSEIF came with 2.4.4
CMAKE_MINIMUM_REQUIRED(VERSION 2.4.4 FATAL_ERROR)

PROJECT(Lintel)

# http://www.vtk.org/Bug/view.php?id=8164
ADD_CUSTOM_TARGET(bug-8164-workaround COMMAND true)
SET_DIRECTORY_PROPERTIES(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ".deptool.build_stamp")

IF(COMMAND CMAKE_POLICY)
    CMAKE_POLICY(SET CMP0003 NEW) # don't warn about -lpthread, it's ok.
    CMAKE_POLICY(SET CMP0005 OLD) # we escape a string definition in src/CMakeLists.txt
    # once we are cmake 2.6 and above only we can set this to new and remove the escaping
ENDIF(COMMAND CMAKE_POLICY)

SET(LINTEL_VERSION 0.0)
SET(LINTEL_ABI_VERSION 0)
SET(LINTELPTHREAD_ABI_VERSION 0)

# Tells CMake where to look when using FIND_PACKAGE() or INCLUDE()
SET(CMAKE_MODULE_PATH "${Lintel_SOURCE_DIR}/cmake-modules" ${CMAKE_MODULE_PATH})

INCLUDE("CMakeConfig.txt")
INCLUDE(LintelCMakeUtil)

ENABLE_TESTING()

ADD_SUBDIRECTORY(include/Lintel)
ADD_SUBDIRECTORY(src)
ADD_SUBDIRECTORY(doc)
ADD_SUBDIRECTORY(cmake-modules)

IF(LINTEL_FIND_ALL_NOTFOUND)
    MESSAGE("")
    MESSAGE("************************************")
    MESSAGE("  Some optional dependency was not found, see above warning messages.")
    MESSAGE("  ${CMAKE_CURRENT_SOURCE_DIR}/doc/dependencies.txt")
    MESSAGE("  may help identify the right packages")
    MESSAGE("************************************")
    MESSAGE("")
ENDIF(LINTEL_FIND_ALL_NOTFOUND)

