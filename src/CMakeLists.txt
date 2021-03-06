#
# (c) Copyright 2007-2008, Hewlett-Packard Development Company, LP
#
#  See the file named COPYING for license details
#
# cmake rules for the src directory

INCLUDE_DIRECTORIES(
	${Lintel_SOURCE_DIR}/include
	${Lintel_BINARY_DIR}/include
	${CMAKE_CURRENT_BINARY_DIR}/include
	${Boost_INCLUDE_DIRS}
	)

ADD_DEFINITIONS(-DLIBLINTEL_VERSION="\\"${LINTEL_VERSION}\\"")
IF(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    ADD_DEFINITIONS(-DDEBUG)
ENDIF(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
		       
IF(CMAKE_COMPILER_IS_GNUCXX)
# Note -Wextra warns about unused parameters in LintelPerl.cpp auto-generated code
# See http://www.semantics.org/talknotes/SD2002W_HIERARCHY.pdf slide 10 about overloaded-virtual
    ADD_DEFINITIONS(-Wall -Wextra -Woverloaded-virtual -Wpointer-arith -Wwrite-strings)
# TODO: get these in and mostly cleaned up
# -Wold-style-cast -Weffc++
ENDIF(CMAKE_COMPILER_IS_GNUCXX)

# these rely on threading support. Currently, Lintel only knows pthreads.
IF (THREADS_ENABLED)
    SET (LIBLINTEL_THREAD_SOURCES
	Clock.cpp
	LintelLog.cpp
	SimpleMutex.cpp
    )
ENDIF (THREADS_ENABLED)

SET(LIBLINTEL_SOURCES
	AssertBoost.cpp
	AssertException.cpp
	BoyerMooreHorspool.cpp
	ConstantString.cpp
	Deque.cpp
	Double.cpp
	HashFns.cpp
	HashTable.cpp
	LeastSquares.cpp
	LintelVersion.cpp
	MathSpecialFunctions.cpp
	Matrix.cpp
	MersenneTwisterRandom.cpp
	PriorityQueue.cpp
	Stats.cpp
	StatsEMA.cpp
	StatsHistogram.cpp
	StatsMaker.cpp
	StatsRW.cpp
	StatsQuantile.cpp
	StatsSequence.cpp
	StatsSeries.cpp
	StatsSeriesGroup.cpp
	StringUtil.cpp
        TestUtil.cpp
	${LIBLINTEL_THREAD_SOURCES}
)

SET(LINTEL_FEATURES boost)

################################## PROGRAMS

MACRO(LINTEL_SIMPLE_PROGRAM program_name)
  ADD_EXECUTABLE(${program_name} ${program_name}.cpp)
  ADD_DEPENDENCIES(${program_name} Lintel)
  TARGET_LINK_LIBRARIES(${program_name} Lintel)
ENDMACRO(LINTEL_SIMPLE_PROGRAM)

LINTEL_SIMPLE_PROGRAM(drawRandomLogNormal)
LINTEL_POD2MAN(drawRandomLogNormal.cpp 1 "Lintel ${LINTEL_VERSION}" "-" drawRandomLogNormal.1)

################################## PERL MODULES

IF(PERL_ENABLED)
    LINTEL_INSTALL_FILE_PATH(${CMAKE_INSTALL_PREFIX}/share/perl5
    	Text/Expand.pm
    	Lintel/File/Lock.pm
        Lintel/SHA1.pm
    )

    IF(PERL_DIGEST_HMAC_ENABLED AND SSH_ENABLED)
        LINTEL_INSTALL_FILE_PATH(${CMAKE_INSTALL_PREFIX}/share/perl5
       	    Lintel/Net/SSH/KnownHostsFile.pm
        )
    ENDIF(PERL_DIGEST_HMAC_ENABLED AND SSH_ENABLED)

    IF(PERL_TIME_HIRES_ENABLED)
        LINTEL_INSTALL_FILE_PATH(${CMAKE_INSTALL_PREFIX}/share/perl5
  	    Lintel/ProcessManager.pm
        )
    ENDIF(PERL_TIME_HIRES_ENABLED)
ENDIF(PERL_ENABLED)

IF(LINTEL_DBI_ENABLED)
    LINTEL_INSTALL_FILE_PATH(${CMAKE_INSTALL_PREFIX}/share/perl5
        Lintel/DBI.pm
    )
ENDIF(LINTEL_DBI_ENABLED)


IF(MERCURY_PLOT_ENABLED)
    LINTEL_INSTALL_FILE_PATH(${CMAKE_INSTALL_PREFIX}/share/perl5
    	Plot/Mercury.pm
    	Plot/Mercury/Tics.pm
    )
ENDIF(MERCURY_PLOT_ENABLED)

################################## CONDITIONAL BITS

IF(ENABLE_STDIO64)
    LIST(APPEND LINTEL_FEATURES stdio64)
    LIST(APPEND LIBLINTEL_SOURCES stdio_64.cpp)
ENDIF(ENABLE_STDIO64)

IF(THREADS_ENABLED)
    LIST(APPEND LINTEL_FEATURES threads)
    SET(LIBLINTELPTHREAD_SOURCES PThread.cpp ClockPThread.cpp)
ENDIF(THREADS_ENABLED)

IF(LIBXML2_ENABLED)
    INCLUDE_DIRECTORIES(${LIBXML2_INCLUDE_DIR})
    LIST(APPEND LINTEL_FEATURES libxml2)
    LIST(APPEND LIBLINTEL_SOURCES LintelLogXML.cpp XMLUtil.cpp)
ENDIF(LIBXML2_ENABLED)

IF(LATEX_ENABLED)
    LINTEL_INSTALL_CONFIG_POD2MAN_PROGRAM(lintel-latex-rebuild 1 "Lintel ${LINTEL_VERSION}")
ENDIF(LATEX_ENABLED)

IF(BOOST_PROGRAM_OPTIONS_ENABLED)
    LIST(APPEND LINTEL_FEATURES program-options)
    LIST(APPEND LIBLINTEL_SOURCES ProgramOptions.cpp)
ENDIF(BOOST_PROGRAM_OPTIONS_ENABLED)

IF(PERL_ENABLED)
    LIST(APPEND LINTEL_FEATURES perl)
ENDIF(PERL_ENABLED)

IF(WITH_PROCESS_STATISTICS)
    LIST(APPEND LINTEL_FEATURES process-statistics)
    LIST(APPEND LIBLINTEL_SOURCES unstable/ProcessStatistics.cpp)
ENDIF(WITH_PROCESS_STATISTICS)

################################## LIBRARY

ADD_LIBRARY(Lintel ${LIBRARY_TYPE} ${LIBLINTEL_SOURCES})
SET_TARGET_PROPERTIES(Lintel 
    PROPERTIES VERSION ${LINTEL_VERSION} SOVERSION ${LINTEL_ABI_VERSION})

IF ("${LINTEL_SYSTEM_TYPE}" STREQUAL "OpenBSD")
    # OpenBSD does not have stubs for the lock/unlock operations that link when you don't
    # enable threading.  Therefore since a bit of lintel relies on those operations we have
    # to always link with threads.
    IF (NOT THREADS_ENABLED)
        FATAL_ERROR("Can not build on OpenBSD without threads")
    ENDIF (NOT THREADS_ENABLED)
    TARGET_LINK_LIBRARIES(Lintel ${CMAKE_THREAD_LIBS_INIT})
ENDIF ("${LINTEL_SYSTEM_TYPE}" STREQUAL "OpenBSD")

################################## CONDITIONAL LIBRARY

IF(LIBXML2_ENABLED)
    TARGET_LINK_LIBRARIES(Lintel ${LIBXML2_LIBRARIES})
ENDIF(LIBXML2_ENABLED)

IF(BOOST_PROGRAM_OPTIONS_ENABLED)
    TARGET_LINK_LIBRARIES(Lintel ${BOOST_PROGRAM_OPTIONS_LIBRARIES})
ENDIF(BOOST_PROGRAM_OPTIONS_ENABLED)

IF(THREADS_ENABLED)
    ADD_LIBRARY(LintelPThread ${LIBRARY_TYPE} ${LIBLINTELPTHREAD_SOURCES})
    ADD_DEPENDENCIES(LintelPThread Lintel)
    SET_TARGET_PROPERTIES(LintelPThread
        PROPERTIES VERSION ${LINTEL_VERSION} SOVERSION ${LINTELPTHREAD_ABI_VERSION})
    TARGET_LINK_LIBRARIES(LintelPThread Lintel ${BOOST_THREAD_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
ENDIF(THREADS_ENABLED)

################################## SUBDIRS

ADD_SUBDIRECTORY(BatchParallel)
IF(PERL_ENABLED)
    ADD_SUBDIRECTORY(perl)
ENDIF(PERL_ENABLED)

ADD_SUBDIRECTORY(tests)

################################## INSTALL

INSTALL(TARGETS drawRandomLogNormal DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
INSTALL(TARGETS Lintel DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
IF(${CMAKE_SYSTEM_NAME} STREQUAL "CYGWIN")
  INSTALL(TARGETS Lintel DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
ENDIF(${CMAKE_SYSTEM_NAME} STREQUAL "CYGWIN")
LINTEL_INSTALL_CONFIG_POD2MAN_PROGRAM(lintel-config 1 "Lintel ${LINTEL_VERSION}")

IF(PERL_ENABLED) 
    LINTEL_INSTALL_CONFIG_POD2MAN_PROGRAM(batch-parallel 1 "Lintel ${LINTEL_VERSION}")
    LINTEL_INSTALL_CONFIG_POD2MAN_PROGRAM(lintel-flock 1 "Lintel ${LINTEL_VERSION}")
    LINTEL_INSTALL_CONFIG_POD2MAN_PROGRAM(deptool 1 "Lintel ${LINTEL_VERSION}")
    # Built, but intentionally not installed.
    ADD_CUSTOM_TARGET(deptool-bootstrap ALL 
                      COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/make-deptool-bootstrap.sh
    		          ${CMAKE_CURRENT_SOURCE_DIR} 
    		      DEPENDS deptool.in Lintel/File/Lock.pm Lintel/ProcessManager.pm)
ELSE(PERL_ENABLED)
    MESSAGE("deptool will NOT be built.  Could not find perl")
ENDIF(PERL_ENABLED) 


IF(PERL_ENABLED AND SFDISK_ENABLED AND SGINFO_ENABLED)
    LINTEL_INSTALL_CONFIG_POD2MAN_PROGRAM(lintel-disktool 1 "Lintel ${LINTEL_VERSION}")
ENDIF(PERL_ENABLED AND SFDISK_ENABLED AND SGINFO_ENABLED)

IF(MERCURY_PLOT_ENABLED)
    # explicitly setting the section type to the default to test that LINTEL_POD2MAN works properly.
    LINTEL_INSTALL_CONFIG_POD2MAN_PROGRAM(mercury-plot 1 "Lintel ${LINTEL_VERSION}" "User Commands")
ENDIF(MERCURY_PLOT_ENABLED)

LINTEL_INSTALL_CONFIG_FILE(redhat-rules 
	${CMAKE_INSTALL_PREFIX}/share/packaging)

IF(THREADS_ENABLED)
  INSTALL(TARGETS LintelPThread DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
  IF(${CMAKE_SYSTEM_NAME} STREQUAL "CYGWIN")
    INSTALL(TARGETS LintelPThread DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
  ENDIF(${CMAKE_SYSTEM_NAME} STREQUAL "CYGWIN")
ENDIF(THREADS_ENABLED)
