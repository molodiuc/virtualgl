# This file is included from the top-level CMakeLists.txt.  We just store it
# here to avoid cluttering up that file.

set(PKGNAME ${CMAKE_PROJECT_NAME} CACHE STRING
	"Distribution package name (default: ${CMAKE_PROJECT_NAME})")
string(TOLOWER ${PKGNAME} PKGNAME_LC)
set(PKGVENDOR "The ${CMAKE_PROJECT_NAME} Project" CACHE STRING
	"Vendor name to be included in distribution package descriptions (default: The ${CMAKE_PROJECT_NAME} Project)")
set(PKGURL "http://www.${CMAKE_PROJECT_NAME}.org" CACHE STRING
	"URL of project web site to be included in distribution package descriptions (default: http://www.${CMAKE_PROJECT_NAME}.org)")
set(PKGEMAIL "information@${CMAKE_PROJECT_NAME}.org" CACHE STRING
	"E-mail of project maintainer to be included in distribution package descriptions (default: information@${CMAKE_PROJECT_NAME}.org")
set(PKGID "com.${CMAKE_PROJECT_NAME_LC}.vglclient" CACHE STRING
	"Globally unique package identifier (reverse DNS notation) (default: com.${CMAKE_PROJECT_NAME_LC}.vglclient)")


if(UNIX AND NOT CMAKE_INSTALL_PREFIX MATCHES "^/usr/?$")
	set(DEFAULT_VGL_BINSYMLINKS 0)
	set(DEFAULT_VGL_INCSYMLINKS 0)
	if(CMAKE_INSTALL_PREFIX STREQUAL "${CMAKE_INSTALL_DEFAULT_PREFIX}")
		set(DEFAULT_VGL_BINSYMLINKS 1)
		set(DEFAULT_VGL_INCSYMLINKS 1)
	endif()
	option(VGL_BINSYMLINKS
		"In the distribution packages, create symlinks to VirtualGL binaries and scripts under /usr/bin (default: @DEFAULT_VGL_BINSYMLINKS@)"
		${DEFAULT_VGL_BINSYMLINKS})
	boolean_number(VGL_BINSYMLINKS)
	option(VGL_INCSYMLINKS
		"In the distribution packages, create symlinks to VirtualGL headers under /usr/include (default: @DEFAULT_VGL_INCSYMLINKS@)"
		${DEFAULT_VGL_INCSYMLINKS})
	boolean_number(VGL_INCSYMLINKS)
else()
	set(VGL_BINSYMLINKS 0)
	set(VGL_INCSYMLINKS 0)
endif()


###############################################################################
# Linux RPM and DEB
###############################################################################

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")

set(RPMARCH ${CMAKE_SYSTEM_PROCESSOR})
if(CPU_TYPE STREQUAL "x86_64")
	set(DEBARCH amd64)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv7*")
	set(DEBARCH armhf)
elseif(CPU_TYPE STREQUAL "arm64")
	set(DEBARCH ${CPU_TYPE})
elseif(CPU_TYPE STREQUAL "arm")
	set(DEBARCH armel)
elseif(CMAKE_SYSTEM_PROCESSOR_LC STREQUAL "ppc64le")
	set(DEBARCH ppc64el)
else()
	set(DEBARCH ${CMAKE_SYSTEM_PROCESSOR})
endif()
message(STATUS "RPM architecture = ${RPMARCH}, DEB architecture = ${DEBARCH}")

configure_file(release/makerpm.in pkgscripts/makerpm)
configure_file(release/rpm.spec.in pkgscripts/rpm.spec @ONLY)

add_custom_target(rpm sh pkgscripts/makerpm
	SOURCES pkgscripts/makerpm)

configure_file(release/makesrpm.in pkgscripts/makesrpm)

add_custom_target(srpm sh pkgscripts/makesrpm
	SOURCES pkgscripts/makesrpm
	DEPENDS dist)

configure_file(release/makedpkg.in pkgscripts/makedpkg)
configure_file(release/deb-control.in pkgscripts/deb-control)

add_custom_target(deb sh pkgscripts/makedpkg
	SOURCES pkgscripts/makedpkg)

endif() # Linux


###############################################################################
# Windows installer (NullSoft Installer)
###############################################################################

if(WIN32)

if(BITS EQUAL 64)
	set(INST_DEFS -DWIN64)
endif()

if(MSVC_IDE)
	set(INST_DEFS ${INST_DEFS} "-DBUILDDIR=${CMAKE_CFG_INTDIR}\\")
else()
	set(INST_DEFS ${INST_DEFS} "-DBUILDDIR=")
endif()

configure_file(release/installer.nsi.in pkgscripts/installer.nsi @ONLY)

if(MSVC_IDE)
	add_custom_target(installer
		COMMAND ${CMAKE_COMMAND} -E make_directory @CMAKE_BINARY_DIR@/${CMAKE_CFG_INTDIR}
		COMMAND makensis -nocd ${INST_DEFS} pkgscripts/installer.nsi
		DEPENDS tcbench nettest wglspheres
		SOURCES pkgscripts/installer.nsi)
else()
	add_custom_target(installer
		COMMAND makensis -nocd ${INST_DEFS} pkgscripts/installer.nsi
		DEPENDS tcbench nettest wglspheres
		SOURCES pkgscripts/installer.nsi)
endif()

endif() # WIN32


###############################################################################
# Cygwin Package
###############################################################################

if(CYGWIN)

configure_file(release/makecygwinpkg.in pkgscripts/makecygwinpkg)

add_custom_target(cygwinpkg sh pkgscripts/makecygwinpkg)

endif() # CYGWIN


###############################################################################
# Mac DMG
###############################################################################

if(APPLE)

set(DEFAULT_OSX_32BIT_BUILD ${CMAKE_SOURCE_DIR}/osxx86)
set(OSX_32BIT_BUILD ${DEFAULT_OSX_32BIT_BUILD} CACHE PATH
	"Directory containing 32-bit (i386) Mac build to include in universal binaries (default: ${DEFAULT_OSX_32BIT_BUILD})")

string(REGEX REPLACE "/" ":" CMAKE_INSTALL_MACPREFIX ${CMAKE_INSTALL_PREFIX})
string(REGEX REPLACE "^:" "" CMAKE_INSTALL_MACPREFIX
	${CMAKE_INSTALL_MACPREFIX})

configure_file(release/makemacpkg.in pkgscripts/makemacpkg)
configure_file(release/Distribution.xml.in pkgscripts/Distribution.xml)
configure_file(release/uninstall.in pkgscripts/uninstall)
configure_file(release/uninstall.applescript.in pkgscripts/uninstall.applescript)

add_custom_target(dmg sh pkgscripts/makemacpkg
	SOURCES pkgscripts/makemacpkg)

add_custom_target(udmg sh pkgscripts/makemacpkg universal
	SOURCES pkgscripts/makemacpkg)

endif() # APPLE


###############################################################################
# Generic
###############################################################################

configure_file(release/makesrpm.in pkgscripts/makesrpm)

set(PROJECT_NAME ${CMAKE_PROJECT_NAME})
if(WIN32)
	string(REGEX REPLACE "-Utils" "" PROJECT_NAME ${CMAKE_PROJECT_NAME})
endif()
add_custom_target(dist
	COMMAND git archive --prefix=${PROJECT_NAME}-${VERSION}/ HEAD |
		gzip > ${CMAKE_BINARY_DIR}/${PROJECT_NAME}-${VERSION}.tar.gz
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

configure_file(release/maketarball.in pkgscripts/maketarball)

add_custom_target(tarball sh pkgscripts/maketarball
	SOURCES pkgscripts/maketarball)
