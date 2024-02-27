###############################################################################
# Makefile for libFAUDES, tmoor 20240216
#
# Requires GNU make
#
# PLATFORM:
#
# Unix/posix environment (Linux, Mac OSX) or Win32; see compiler options below. 
#
# USER TARGETS: 
# 
# default:    build library and utility executables
# libfaudes:  build libfaudes library
# tutorial:   build all examples from tutorial sections
# clean:      remove intermediate objects etc
# test:       validate test cases (requires tutorials)
#
# DEVELOPER TARGETS
#
# dist-clean: clear all configuration
# configure:  autogenerate includes and documentation files wrt 
#             compiletime options and plug-ins
# package:    prepare tgz-archive
#
#
# CONFIGURATION
#
# The target "configure" uses the variables FAUDES_PLUGINS, FAUDES_DEBUG
# and FAUDES_OPTIONS to configure sources, the run-time interface and documentaion. The
# variables are cached in Makefile.configuration. Any change of these variables requires
# a "make dist-clean", "make configure" to take an effect.
#
# In contrast, FAUDES_PLATFORM, FAUDES_LINKING, including the derived commandline tools 
# (compiler options etc) can be changed withour re-configuring the libFAUDES sources. 
# The startingpoint is to download the pre-configured libFAUDES sources and finetune the 
# compilation and linking process your target platform by "FAUDES_PLATFORM=xxx_xx" with 
# predefined choices discussed below.
#
###############################################################################



###############################################################################
#
# Configure Plug-Ins
#
# Setting the environment variable FAUDES_PLUGINS to a space separated list
# of plug-ins will include the corresponding plug-in makefiles to append
# additional sources and to register the plug-in in include/configuration.h. 
#
# Note: this only takes effect with the target "configure"
#
###############################################################################

# manualy enable plug-ins (uncomment corresponding lines)

# note: only enable those plug-ins you need/know
# note: do not enable both Lua and Pyhton bindings simultaneosly 

ifeq ($(FAUDES_PLUGINS),)
FAUDES_PLUGINS = 
#FAUDES_PLUGINS += example
FAUDES_PLUGINS += synthesis
FAUDES_PLUGINS += observer
FAUDES_PLUGINS += multitasking
FAUDES_PLUGINS += diagnosis
FAUDES_PLUGINS += hiosys
FAUDES_PLUGINS += iosystem
FAUDES_PLUGINS += coordinationcontrol
FAUDES_PLUGINS += timed
FAUDES_PLUGINS += simulator
FAUDES_PLUGINS += iodevice
#FAUDES_PLUGINS += pushdown
#FAUDES_PLUGINS += hybrid
FAUDES_PLUGINS += luabindings
#FAUDES_PLUGINS += pybindings
endif



###############################################################################
# Configure core features
#
# Set the environment variable FAUDES_OPTIONS to select optional features to
# be included with the build. 
#
# Note: this only takes effect with the target "configure"
#
###############################################################################

ifeq ($(FAUDES_OPTIONS),)

# elementary systemtime (gettimeofday wrappers)
FAUDES_OPTIONS += core_systime

# elementary networking (including headers, requires systime)
FAUDES_OPTIONS += core_network

# elementary thread support (mimic POXIS threads, requires systime)
FAUDES_OPTIONS += core_threads

endif


###############################################################################
# Configure console output i.e. debug level
#
# Set the environment variable FAUDES_DEBUG to configure the console-out 
# behaviour of libFAUDES.
#
# Note: this only takes effect with the target "configure"
#
###############################################################################


ifeq ($(FAUDES_DEBUG),)

#   core_checked
#      Turns on consistency tests on input data. Tests may introduce a slight
#      run-time overhead and through exceptions when a mismatch is detected.
#      If your application performs input data consistency, you may disable
#      this option. 
FAUDES_DEBUG += core_checked

#   core_code
#      Turns on consistency tests on internal data structures. Tests may introduce
#      a massive overhead and silently abort the application when inconsistency is
#      detected. This should be only activated during development.
#FAUDES_DEBUG += core_code

#   core_exceptions  
#      Write exceptions to stderr. For applications that catch exceptions and 
#      translate them a user friendly report, you may want to disable this option.
FAUDES_DEBUG += core_exceptions

#   core_compatibility
#      Enables code that is intended for backward compatibility. E.g. include
#      typedefs with pre 2.20b class names; read pre 2.18b token streams. Note, however,
#      that there is no attempt to achieve full backward compatibility. Changes in libFAUDES,
#      that are expected to affect applications/plug-ins are logged in the CHANGES file.
#      When developing new applications, you should disable this option. 
FAUDES_DEBUG += core_compatibility

#   core_function 
#      Print function debug messages (parallel, trim, etc)
#FAUDES_DEBUG += core_function

#   core_generator  
#      Print Generator debug messages (this is very verbose)
#FAUDES_DEBUG += core_generator

#   core_container
#      Print container (StateSet, EventSet, TransSet) debug messages.
#FAUDES_DEBUG += core_container

#   core_fregistry  
#      Report on type and function registration
#FAUDES_DEBUG += core_fregistry

#   core_finterface  
#      Report on type and function definitions
#FAUDES_DEBUG += core_finterface

#   core_fverbose  
#      Print even more verbose debug messages (iterations, tokenio)
#FAUDES_DEBUG += core_fverbose

#   core_progress
#      Write function progress to console (not every functions support this feature)
#FAUDES_DEBUG += core_progress

endif

#
#
###############################################################################


# Include confiure cache to recover FAUDES_PLUGINS, FAUDES_DEBUG, and FAUDES_OPTIONS

FILE_CONFIG = Makefile.configuration

# if "configuration" are "dist-clean" are not the target, read make varaibles from file
ifneq (configure,$(findstring configure,$(MAKECMDGOALS)))
ifneq (dist-clean,$(findstring dist-clean,$(MAKECMDGOALS)))
include $(FILE_CONFIG)
endif
endif



###############################################################################
# Choose linking
#
# Set the environment variable FAUDES_LINKING to choose to compile the libFAUDES 
# library for "shared" or for "static" linking, either with or without debugging 
# symbols; i.e. choices are "shared", "static", "shared debug" or "static debug".
#
# Note: although shared is the default, a number of elementary configuration
# tools will link statically regardless the below option.
#
# Note: changing this option requires a "make clean" 
#
###############################################################################

ifeq ($(FAUDES_LINKING),)
FAUDES_LINKING = shared 
#FAUDES_LINKING = static debug
endif

ifneq ($(filter shared,$(FAUDES_LINKING)),)
SHARED=yes
else
SHARED=no
endif
ifneq ($(filter debug,$(FAUDES_LINKING)),)
DEBUG=yes
else
DEBUG=no
endif




###############################################################################
#
# Derive compiler/linker options from FAUDES_PLATFORM
#
# If you dont trust the Makefile to autodetect your platform, invoke
# make with "FAUDES_PLATFORM=xx_yyy" with "xx_yyy" specifying your platform.
#
###############################################################################


### try to autoselect platform
# Ms Windows with MS Visual C compilers
ifeq ($(FAUDES_PLATFORM),)
ifneq ($(findstring Windows,$(OS)),)
FAUDES_PLATFORM := cl_win
endif
endif
# Mac OS X with g++ from the XCode toochain
ifeq ($(FAUDES_PLATFORM),)
ifneq ($(findstring Darwin,$(shell uname -s)),)
FAUDES_PLATFORM := gcc_osx
endif
endif
# Linux with the system g++ compiler
ifeq ($(FAUDES_PLATFORM),)
ifneq ($(findstring Linux,$(shell uname -s)),)
FAUDES_PLATFORM := gcc_linux
endif
endif
# Fallback generix Unix environment with g++ compiler
ifeq ($(FAUDES_PLATFORM),)
FAUDES_PLATFORM := gcc_generic
endif

### sensible/posix defaults: generic g++ compiler on a Unix system
#
CXX = g++ 
CC = gcc 
LXX = g++
AR = ar -sr
COUTOPT = -o 
LOUTOPT = -o 
AOUTOPT =
MAINOPTS = -O2
WARNINGS = -Wall 
DSOOPTS = -shared 
DOT_O  = .o
DOT_EXE = 
LNKLIBS = 
ifeq ($(SHARED),yes)
LIBOPTS = -DFAUDES_BUILD_DSO
APPOPTS = -DFAUDES_BUILD_APP
endif

### sensible/posix defaults: external tools #########################
#
CP  = /bin/cp -p 
CPR = /bin/cp -pR
RM = /bin/rm -rf
MKDIR = /bin/mkdir
ECHOE = echo -e
TEMP = /tmp
DOXYGEN = doxygen
SHELL = /bin/bash
DIFF = diff -w --context=3 --show-function-line=mark 
SWIG = swig
PYTHON = python3
FNCT_FIXDIRSEP = $(1)
FNCT_POST_APP = strip $(1)


### sensible/posix defaults: library target names  #################
#

LIBFAUDES = libfaudes
IMPFAUDES = libfaudes
MINFAUDES = minfaudes
ifeq ($(DEBUG),yes)
LIBFAUDES := $(LIBFAUDES)d
IMPFAUDES := $(IMPFAUDES)d
MINFAUDES := $(MINFAUDES)d
endif
ifeq ($(SHARED),yes)
LIBFAUDES := $(LIBFAUDES).so
IMPFAUDES := $(IMPFAUDES).so
MINFAUDES := $(MINFAUDES).a
else
LIBFAUDES := $(LIBFAUDES).a
IMPFAUDES := $(IMPFAUDES).a
MINFAUDES := $(MINFAUDES).a
endif



### platform "gcc_linux": Linux with g++ 4.x and 5.x series #################
# * we moved to CXX11 ABI and C++11 default with Uduntu 16.04 LTS
# * we stopped specifying ABI/C++-dialect explicitly to let the system choose
#
ifeq ($(FAUDES_PLATFORM),gcc_linux)
MAINOPTS = -fpic -fstrict-aliasing -fmessage-length=0 -O3 -iquote
#MAINOPTS += -std=gnu++98 -D_GLIBCXX_USE_CXX11_ABI=0 
#MAINOPTS += -std=gnu++11 -D_GLIBCXX_USE_CXX11_ABI=1 
MAINOPTS += -std=gnu++11
WARNINGS = -pedantic -Wall -Wno-unused-variable -Wno-unused-but-set-variable
LDFLAGS += -Wl,--as-needed  
ifeq ($(DEBUG),yes)
MAINOPTS += -g
endif 
ifeq ($(SHARED),yes)
LIBOPTS += -fvisibility=hidden -fvisibility-inlines-hidden 
LDFLAGS += -Wl,-rpath='$$ORIGIN:$$ORIGIN/../lib:$$ORIGIN/../:$$ORIGIN/../../../'
endif 
ifeq (core_threads,$(findstring core_threads,$(FAUDES_OPTIONS)))
LNKLIBS += -lpthread 
endif
endif

### platform "gcc_linux32": 32bit Linux with g++ 4.x series #################
#
ifeq ($(FAUDES_PLATFORM),gcc_linux32)
MAINOPTS = -m32 -fpic -fstrict-aliasing -fmessage-length=0 -O3 -iquote
WARNINGS = -pedantic -Wall
LDFLAGS += -m32 -Wl,--as-needed  
ifeq ($(DEBUG),yes)
MAINOPTS += -g
endif 
ifeq ($(SHARED),yes)
LIBOPTS += -fvisibility=hidden -fvisibility-inlines-hidden 
LDFLAGS += -Wl,-rpath='$$ORIGIN:$$ORIGIN/../lib:$$ORIGIN/../:$$ORIGIN/../../../'
endif 
ifeq (core_threads,$(findstring core_threads,$(FAUDES_OPTIONS)))
LNKLIBS += -lpthread 
endif
endif


### platform "lsb_linux": Linux with LSB SDK ########################
#
# variant for  SDK 4.1.8, using
# -- Ubuntu 10.04 LTS with gcc 4.4.3 target lsb 3.2
# -- Debian 7.4 with gcc 4.7.2 target lsb 3.2
# -- Ubuntu 16.04 LTS withh gcc 7.3.0 target lsb 4.1
# note: dropping -fpic was needed for gcc 4.7.2 with Lua 
# note: not hiding DSO-symbols here for simplicity
# note: we dont support debug build for LSB
ifeq ($(FAUDES_PLATFORM),lsb_linux)
CXX = /opt/lsb/bin/lsbc++ --lsb-target-version=4.1 --lsb-besteffort
CC = /opt/lsb/bin/lsbcc   --lsb-target-version=4.1 --lsb-besteffort
LXX = /opt/lsb/bin/lsbc++ --lsb-target-version=4.1 --lsb-besteffort
MAINOPTS =  -fPIC -fstrict-aliasing -fmessage-length=0 -O3 -fno-stack-protector -std=gnu++98 
WARNINGS = -Wall -Wno-unused-variable -Wno-unused-but-set-variable
LDFLAGS += -Wl,--as-needed
ifeq ($(SHARED),yes)
LDFLAGS += -Wl,-rpath='$$ORIGIN:$$ORIGIN/../lib:$$ORIGIN/../:$$ORIGIN/../../../'
endif 
ifeq ($(DEBUG),yes)
MAINOPTS += -g
endif 
ifeq (core_threads,$(findstring core_threads,$(FAUDES_OPTIONS)))
LNKLIBS += -lpthread 
endif
endif


### platform "gcc_osx": Mac OS X 10.5 and later #####################
#
# - we have used Xtools provided by Mac OS X 10.5, Mac OS X 10.7
#   and Mac OS X 10.11 during development of libFAUDES.
# - as of libFAUDES 2.27i, only the Mac OS X 10.10 environment is
#   available for testing
# - note that the compiler here is actualy LLVM/clang++ version 7.0.3
# - test deployment target by "otool -l FILE | grep version"
# - moving to libc++ and c11, we now should target for OS X 10.9 (although 10.7 still works)
#
ifeq ($(FAUDES_PLATFORM),gcc_osx)
#
CXX = clang++ -std=gnu++11 
CC = clang
LXX = clang++
#
MAINOPTS =  -O2 -iquote  -mmacosx-version-min=10.9 -stdlib=libc++ 
WARNINGS = -pedantic -Wall -Wno-unused-variable -Wno-unused-but-set-variable -Wno-zero-length-array
DSOOPTS = -dynamiclib  -single_module 
ECHOE = echo -e
# 
export MACOSX_DEPLOYMENT_TARGET = 10.9
#
ifeq ($(DEBUG),yes)
MAINOPTS += -g
LDFLAGS += -g
endif 
ifeq ($(SHARED),yes)
LIBOPTS += -fvisibility=hidden -fvisibility-inlines-hidden  
LDFLAGS +=  -Wl,-rpath,@executable_path/.,-rpath,@executable_path/../lib,-rpath,@executable_path/../,-rpath,@executable_path/../../../ -stdlib=libc++
FNCT_POST_APP = install_name_tool -change libfaudes.dylib @rpath/libfaudes.dylib $(1); strip $(1) 
endif 
ifeq (core_threads,$(findstring core_threads,$(FAUDES_OPTIONS)))
LNKLIBS += -lpthread 
endif
#
ifeq ($(SHARED),yes)
LIBFAUDES = libfaudes
IMPFAUDES = libfaudes
MINFAUDES = minfaudes
ifeq ($(DEBUG),yes)
LIBFAUDES := $(LIBFAUDES)d
IMPFAUDES := $(IMPFAUDES)d
MINFAUDES := $(MINFAUDES)d
endif
LIBFAUDES := $(LIBFAUDES).dylib
IMPFAUDES := $(IMPFAUDES).dylib
MINFAUDES := $(MINFAUDES).a
endif
endif


### platform "cl_win": MS Visual C compiler cl ######################
#
# Validated to compile as of libFAUDES 2.27 with VC2012 as well 
# as VC2015 compilers in their 64bit variant.
#
# [for user targets only, no configuration tools available]
#
ifeq ($(FAUDES_PLATFORM),cl_win)
CP  = cmd /C copy /Y
CPR = cmd /C echo ERROR CPR NOT CONFIGURED
RM = cmd /C del /F /S /Q 
SWIG = cmd /C echo ERROR SWIG NOT CONFIGURED
DIFF = fc /W
CXX = cl.exe /nologo
CC = cl.exe /nologo
LXX = cl.exe /nologo
AR = lib.exe 
DOT_EXE = .exe
DOT_O  = .obj
MAINOPTS = /EHsc /O2 
COUTOPT = /Fo
LOUTOPT = /Fe
AOUTOPT = /OUT:
WARNINGS =  
FNCT_FIXDIRSEP = $(subst /,\,$(1))
#
ifeq ($(DEBUG),yes)
MAINOPTS += /MDd  
LDFLAGS += 
else
MAINOPTS += /MD
LDFLAGS += 
endif 
DSOOPTS = /LD 
LNKLIBS = winmm.lib wsock32.lib 
ifeq ($(SHARED),yes)
LIBOPTS = /DFAUDES_BUILD_DSO
APPOPTS = /DFAUDES_BUILD_APP
endif
#
LIBFAUDES = faudes
IMPFAUDES = faudes
MINFAUDES = minfaudes
ifeq ($(DEBUG),yes)
LIBFAUDES := $(LIBFAUDES)d
IMPFAUDES := $(IMPFAUDES)d
MINFAUDES := $(MINFAUDES)d
endif
ifeq ($(SHARED),yes)
LIBFAUDES := $(LIBFAUDES).dll
IMPFAUDES := $(IMPFAUDES).lib
MINFAUDES := $(MINFAUDES).lib
else
LIBFAUDES := $(LIBFAUDES).lib
IMPFAUDES := $(IMPFAUDES).lib
MINFAUDES := $(MINFAUDES).lib
endif
endif


### platform "gcc_win": MinGW on MS Windows XP 32bit or MS Windows 7 64bit 
#
# We used this toochain for binary distributions up to libFAUDE 2.26;
# -- we dont hide DSO symbols for simplicty
# [for user targets only, no configuration tools available]
#
ifeq ($(FAUDES_PLATFORM),gcc_win)
FNCT_FIXDIRSEP = $(subst /,\,$(1))
CP  = cmd /C copy /Y
CPR = cmd /C echo ERROR CPR NOT CONFIGURED
RM = cmd /C del /F /S /Q 
SWIG = cmd /C echo ERROR SWIG NOT CONFIGURED
DIFF = fc /W
CXX = g++.exe
CC = gcc.exe
LXX = g++.exe
MAINOPTS = -O3 
WARNINGS = -pedantic -Wall 
DSOOPTS = -shared -Wl,-enable-auto-import -Wl,-export-all-symbols 
DOT_EXE = .exe
LNKLIBS = -lwinmm -lwsock32    # winmm for win systime only 
ifeq ($(DEBUG),yes)
MAINOPTS += -g
LDFLAGS +=
endif 
endif

### adapt for emscripten
# (for user targets only, see also luabindings/Makefile.plugin)
# (no debug build here, static linking only)
#
ifeq ($(FAUDES_PLATFORM),emcc_js)
ECHOE = echo -e
CXX = em++
CC = emcc
LXX = em++
AR = emar r
MAINOPTS = -O2 -s DISABLE_EXCEPTION_CATCHING=0
WARNINGS =  
DSOOPTS =
DOT_O  = .o
DOT_EXE = .js
#
ifeq ($(SHARED),yes)
$(error platform emcc_js requires libFAUDES static linking)
endif
ifeq ($(DEBUG),yes)
$(error platform emcc_js doe snot support libFAUDES debugging)
endif
LIBFAUDES := libfaudes.jsa
IMPFAUDES := libfaudes.jsa
MINFAUDES := minfaudes.jsa
FNCT_POST_APP = echo $(1)
endif



### summarize compiler flags in std variable
CFLAGS = $(MAINOPTS) $(WARNINGS) -I$(INCLUDEDIR) $(INCLUDES)


### convenience functions to invoke compiler/linker (1)-->(2)
FNCT_COMP_LIB = $(CXX) -c $(CFLAGS) $(LIBOPTS) $(call FNCT_FIXDIRSEP,$(1)) $(COUTOPT)$(call FNCT_FIXDIRSEP,$(2))
FNCT_COMP_APP = $(CXX) -c $(CFLAGS) $(APPOPTS) $(call FNCT_FIXDIRSEP,$(1)) $(COUTOPT)$(call FNCT_FIXDIRSEP,$(2))
FNCT_LINK_APP = $(LXX) $(call FNCT_FIXDIRSEP,$(1)) $(IMPFAUDES) $(LDFLAGS) $(LNKLIBS) $(LOUTOPT)$(call FNCT_FIXDIRSEP,$(2)) 
FNCT_COMP_MIN = $(CXX) -c $(CFLAGS) -DFAUDES_MUTE_RTIAUTOLOAD $(call FNCT_FIXDIRSEP,$(1)) $(COUTOPT)$(call FNCT_FIXDIRSEP,$(2))
FNCT_BUILD_MIN = $(CXX) $(CFLAGS) $(call FNCT_FIXDIRSEP,$(1)) $(call FNCT_FIXDIRSEP,$(MINFAUDES)) $(LDFLAGS) $(LNKLIBS) $(LOUTOPT)$(call FNCT_FIXDIRSEP,$(2)) 

### more convenience functions
FNCT_COPY = $(CP) $(call FNCT_FIXDIRSEP,$(1)) $(call FNCT_FIXDIRSEP,$(2))



############################################################################################################
############################################################################################################
############################################################################################################
# below this line developpers only ...




####################################
# Get version from file
####################################

include VERSION

FAUDES_VERSION = $(FAUDES_VERSION_MAJOR).$(FAUDES_VERSION_MINOR)
FAUDES_FILEVERSION = $(FAUDES_VERSION_MAJOR)_$(FAUDES_VERSION_MINOR)


####################################
# Libfaudes directory structure
####################################

# where to find core sources (.cpp and doxygen input) 
SRCDIR = src
# where to place binaries 
BINDIR = bin
# where to place all .h files 
INCLUDEDIR = include
# where to place all .o files 
OBJDIR = obj
# where to place the distribution package 
DIST = dist
# where html docu is placed 
DOCDIR = doc
# where doxygen output is placed (via doxygen.conf)
DOXDOCDIR = doc/csource
# where to place html reference output 
REFDOCDIR = doc/reference
# where to luafaudes tutorials
LUADOCDIR = doc/luafaudes
# where to place images
IMGDOCDIR = doc/images
# where to place fref doc sources
REFSRCDIR = doc/refsrc


####################################
# Specify search path for sources
####################################

VPATH = $(SRCDIR)  $(SRCDIR)/registry 

####################################
# Corefaudes Files
####################################


CPPFILESMIN= \
  cfl_platform.cpp cfl_helper.cpp cfl_exception.cpp cfl_token.cpp cfl_tokenreader.cpp cfl_tokenwriter.cpp \
  cfl_types.cpp cfl_functions.cpp cfl_registry.cpp cfl_elementary.cpp cfl_basevector.cpp  

CPPFILES = $(CPPFILESMIN) \
  cfl_symboltable.cpp cfl_attributes.cpp cfl_attrmap.cpp \
  cfl_baseset.cpp cfl_indexset.cpp cfl_symbolset.cpp cfl_nameset.cpp cfl_transset.cpp \
  cfl_generator.cpp cfl_agenerator.cpp cfl_cgenerator.cpp cfl_localgen.cpp \
  cfl_graphfncts.cpp cfl_parallel.cpp cfl_determin.cpp cfl_project.cpp cfl_statemin.cpp\
  cfl_regular.cpp cfl_conflequiv.cpp cfl_bisimulation.cpp cfl_bisimcta.cpp cfl_omega.cpp 


RTIDEFS = cfl_definitions.rti
RTIFREF = reference_index.fref reference_types.fref reference_functions.fref reference_literature.fref \
  corefaudes_index.fref corefaudes_elementary.fref \
  corefaudes_generator.fref corefaudes_alphabet.fref corefaudes_parallel.fref \
  corefaudes_reachability.fref corefaudes_vector.fref corefaudes_langboolean.fref corefaudes_genmisc.fref \
  corefaudes_regular.fref corefaudes_projection.fref corefaudes_statemin.fref

EXECUTABLES = gen2dot fts2ftx  ref2html rti2code flxinstall

HEADERS = $(CPPFILES:.cpp=.h) libfaudes.h configuration.h corefaudes.h allplugins.h cfl_definitions.h  
SOURCES = $(CPPFILES:%=$(SRCDIR)/%)
SOURCESMIN = $(CPPFILESMIN:%=$(SRCDIR)/%)
OBJECTS = $(CPPFILES:%.cpp=$(OBJDIR)/%$(DOT_O)) 
OBJECTSMIN = $(CPPFILESMIN:%.cpp=$(OBJDIR)/%_min$(DOT_O)) 
EXECUTABLES := $(EXECUTABLES:%=$(BINDIR)/%$(DOT_EXE))

RTIDEFS := $(RTIDEFS:%=$(SRCDIR)/registry/%)
RTIFREF := $(RTIFREF:%=$(SRCDIR)/registry/%)

SWGINTERFACES = $(SRCDIR)/swig/corefaudes.i
SWGINCLUDE = -I$(SRCDIR)/swig -I$(INCLUDEDIR)
SWGMODULES = faudes


DEPEND = Makefile.depend

CLEANFILES = $(OBJECTS) $(OBJECTSMIN) $(DEPEND) $(MINFAUDES)

DISTCLEANFILES = $(DEPEND) $(FILE_CONFIG)


####################################
# Two stages of source configuraton
# prepare: move files
# configure: run rti
####################################

PREPARETARGETS = $(FILE_CONFIG) includes

CONFIGURETARGETS =  depend rtitools reftools docs 


####################################
# Declare default target before including 
# other makefiles 
####################################

DEFAULTTARGETS = report-platform libfaudes binaries 

default: default_after_include
	@echo " ============================== " 
	@echo "libFAUDES-make: default targets: done" 
	@echo "libFAUDES-make: you may now compile the tutorials by \"make tutorial\"" 
	@echo " ============================== " 

####################################
# Include generated dependency file
####################################

# if "clean" is goal, do not include a dependency file
ifeq (,$(findstring clean,$(MAKECMDGOALS)))
-include $(DEPEND)
endif


####################################
# Setup plugin indicator variables
####################################

# helper 
emptystring := 
spacestring := $(emptystring) $(emptystring)

# ensure that bindings come last
ifneq ($(findstring luabindings,$(FAUDES_PLUGINS)),)
  FAUDES_PLUGINS := $(filter-out luabindings,$(FAUDES_PLUGINS)) 
  FAUDES_PLUGINS += luabindings
  FAUDES_PLUGINS := $(strip $(FAUDES_PLUGINS))
endif
ifneq ($(findstring pybindings,$(FAUDES_PLUGINS)),)
  FAUDES_PLUGINS := $(filter-out pybindings,$(FAUDES_PLUGINS)) 
  FAUDES_PLUGINS += pybindings
  FAUDES_PLUGINS := $(strip $(FAUDES_PLUGINS))
endif

# using plugins indicator string
pluginstringD = $(subst $(spacestring),-,$(FAUDES_PLUGINS))

# plugin makefiles
pluginstringM = $(patsubst %,./plugins/%/Makefile.plugin,$(FAUDES_PLUGINS))

# plugin directories
pluginstringC = $(patsubst %,./plugins/%,$(FAUDES_PLUGINS))

# plugin image directories
pluginstringI = $(patsubst %,./plugins/%/src/doxygen/faudes_images,$(FAUDES_PLUGINS))

# plugin tutorial directories
pluginstringT = $(patsubst %,./plugins/%/tutorial,$(FAUDES_PLUGINS))

# plugin registry directories
pluginstringR = $(patsubst %,./plugins/%/src/registry,$(FAUDES_PLUGINS))


####################################
# Additional makefiles for plugins
####################################

include Makefile.tutorial

ifneq ($(pluginstringM),)
include $(pluginstringM)
endif

VPATH += $(pluginstringR)

default_after_include: $(DEFAULTTARGETS)

# fix configuration variables (in particular FAUDES_OPTIONS)
ifneq (dist-clean,$(findstring dist-clean,$(MAKECMDGOALS)))
ifneq (configure,$(findstring configure,$(MAKECMDGOALS)))
include $(FILE_CONFIG)
endif
endif

# fix osx ... using macport libraries
ifeq ($(FAUDES_PLATFORM),gcc_osx)
LDFLAGS += -L/opt/local/lib
INCLUDES += -I/opt/local/include
endif

####################################
# Export variables to sub make
####################################

export FAUDES_DEBUG
export FAUDES_PLATFORM
export FAUDES_PLUGINS
export FAUDES_OPTIONS

####################################
# User Targets
####################################

all: dist-clean configure default tutorial tutorial test

includes: $(HEADERS:%=$(INCLUDEDIR)/%) 

prepare: $(PREPARETARGETS)

configure: prepare $(CONFIGURETARGETS)
	@echo " ============================== " 
	@echo "libFAUDES-make: configure: done" 
	@echo "libFAUDES-make: you may now compile the default targets by \"make -j20\"" 
	@echo " ============================== " 

libfaudes: $(LIBFAUDES) includes

binaries: $(EXECUTABLES) includes

tutorial: $(TUTORIAL_EXECUTABLES) $(TUTORIALTARGETS) includes
	@echo " ============================== " 
	@echo "libFAUDES-make: tutorial targets: done" 
	@echo "libFAUDES-make: you may now run the provided test cases by \"make test\"" 
	@echo " ============================== " 

package: 
	$(RM) $(DIST) 
	$(MKDIR) $(DIST) 
	- rm -rf $(TEMP)/libfaudes-$(FAUDES_FILEVERSION) 
	- cp -pR . $(TEMP)/libfaudes-$(FAUDES_FILEVERSION) 
	- cp -pR $(TEMP)/libfaudes-$(FAUDES_FILEVERSION) $(DIST) 
	$(RM) $(DIST)/libfaudes-$(FAUDES_FILEVERSION)/plugins
	$(MKDIR) $(DIST)/libfaudes-$(FAUDES_FILEVERSION)/plugins
	- $(CPR)  $(pluginstringC) $(DIST)/libfaudes-$(FAUDES_FILEVERSION)/plugins
	- $(CPR)  plugins/example $(DIST)/libfaudes-$(FAUDES_FILEVERSION)/plugins
	- $(CPR)  plugins/hybrid $(DIST)/libfaudes-$(FAUDES_FILEVERSION)/plugins
	- $(CPR)  plugins/pybindings $(DIST)/libfaudes-$(FAUDES_FILEVERSION)/plugins
	cd $(DIST)/libfaudes-$(FAUDES_FILEVERSION) ; $(MAKE) dist-clean
	cd $(DIST)/libfaudes-$(FAUDES_FILEVERSION) ; $(MAKE) configure 
	cd $(DIST)/libfaudes-$(FAUDES_FILEVERSION) ; $(MAKE) -j20
	cd $(DIST)/libfaudes-$(FAUDES_FILEVERSION) ; $(MAKE) clean
	tar --verbose --create --gzip --directory="$(DIST)"  --exclude-from=$(SRCDIR)/TAR_EXCLUDES  --file="$(DIST)/libfaudes-$(FAUDES_FILEVERSION).tar.gz" libfaudes-$(FAUDES_FILEVERSION)


####################################
# Clean 
####################################

clean: $(CLEANTARGETS)
	$(RM) $(call FNCT_FIXDIRSEP,$(CLEANFILES)) 
	$(RM) $(call FNCT_FIXDIRSEP,obj/*)
	$(RM) tmp_valext 

dist-clean: doc-clean $(DISTCLEANTARGETS)
	rm -rf $(CLEANFILES) 
	rm -rf $(DISTCLEANFILES) 
	rm -rf $(EXECUTABLES) 
	rm -rf $(BINDIR) 
	rm -rf $(OBJDIR) 
	rm -rf $(DOCDIR) 
	rm -rf $(INCLUDEDIR)/*
	rm -f libfaudes.a libfaudes.so libfaudesd.a libfaudesd.so
	rm -f libfaudes.dylib libfaudesd.dylib  libfaudes.jsa
	rm -f faudes.lib faudes.dll faudesd.lib faudesd.dll
	rm -f minfaudes.a minfaudesd.a minfaudes.jsa minfaudes.lib
	rm -f tutorial/tmp_* 
	rm -f plugins/*/tutorial/tmp_* 
	rm -f plugins/*/tutorial/results/*.* 
	rm -f plugins/*/tutorial/results/*/*.* 
	rm -f obj/* 
	rm -f bin/* 
	rm -f plugins/*/obj/* 
	rm -rf dist
	rm -rf tmp_valext
	rm -f *~  
	rm -f ._*  
	rm -f *.bak  
	rm -f */*~  
	rm -f */._*  
	rm -f */*.bak  
	rm -f */*/*~  
	rm -f */*/._*  
	rm -f */*/*.bak  
	rm -f */*/*/*~  
	rm -f */*/*/._*  
	rm -f */*/*/*.bak  
	rm -f */*/*/*/*~  
	rm -f */*/*/*/._*  
	rm -f */*/*/*/*.bak  
	rm -f */*/*/*/*/*~  
	rm -f */*/*/*/*/._*  
	rm -f */*/*/*/*/*.bak  




####################################
# Configure source files
####################################

$(INCLUDEDIR)/allplugins.h: $(SRCDIR)/allplugins.h.template 
	cp $(SRCDIR)/allplugins.h.template $(INCLUDEDIR)/allplugins.h

$(INCLUDEDIR)/configuration.h: $(SRCDIR)/configuration.h.template 
	cp $(SRCDIR)/configuration.h.template $(INCLUDEDIR)/configuration.h
	echo "/* faudes core configuration */" >> $(INCLUDEDIR)/configuration.h
	echo "#define  FAUDES_VERSION \"libFAUDES $(FAUDES_VERSION)\"" >> $(INCLUDEDIR)/configuration.h
	echo "#define  FAUDES_PLUGINS \"$(pluginstringD)\"" >> $(INCLUDEDIR)/configuration.h
	echo "#define  FAUDES_PLUGINS_RTILOAD {$(FAUDES_PLUGINS_RTILOAD)}" >> $(INCLUDEDIR)/configuration.h
ifeq (core_systime,$(findstring core_systime,$(FAUDES_OPTIONS)))
	echo "#define  FAUDES_SYSTIME" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_network,$(findstring core_network,$(FAUDES_OPTIONS)))
	echo "#define  FAUDES_NETWORK" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_threads,$(findstring core_threads,$(FAUDES_OPTIONS)))
	echo "#define  FAUDES_THREADS" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_checked,$(findstring core_checked,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_CHECKED" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_code,$(findstring core_code,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_CODE" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_exceptions,$(findstring core_exceptions,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_EXCEPTIONS" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_compatibility,$(findstring core_compatibility,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_COMPATIBILITY" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_function,$(findstring core_function,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_FUNCTION" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_generator,$(findstring core_generator,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_GENERATOR" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_container ,$(findstring core_container,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_CONTAINER" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_fverbose,$(findstring core_fverbose,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_VERBOSE" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_progress ,$(findstring core_progress,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_WRITE_PROGRESS" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_fregistry ,$(findstring core_fregistry,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_REGISTRY" >> $(INCLUDEDIR)/configuration.h
endif
ifeq (core_finterface ,$(findstring core_finterface,$(FAUDES_DEBUG)))
	echo "#define  FAUDES_DEBUG_RUNTIMEINTERFACE" >> $(INCLUDEDIR)/configuration.h
endif
	echo " " >> $(INCLUDEDIR)/configuration.h

$(FILE_CONFIG):
	rm -f $@
	touch $@
	echo "# libFAUDES build configuration" >> $@
	echo "# - do not edit this file manually" >> $@
	echo "# - see main Makefile for documentation" >> $@
	echo FAUDES_PLUGINS = $(FAUDES_PLUGINS) >> $@
	echo FAUDES_DEBUG = $(FAUDES_DEBUG) >> $@
	echo FAUDES_OPTIONS = $(FAUDES_OPTIONS) >> $@


####################################
# Run time interface
####################################

# run time interface target
rti: rtitools doc-reference doc-fref

# tools only
rtitools: $(INCLUDEDIR)/libfaudes.rti $(INCLUDEDIR)/rtiautoload.i $(BINDIR)/rti2code$(DOT_EXE) 

# clean
rti-clean:
	- rm -rf $(REFSRCDIR)  
	- rm -rf $(INCLUDEDIR)/rtiautoload*
	- rm -rf $(INCLUDEDIR)/libfaudes.rti

# have those dirs
$(OBJDIR): 
	@mkdir -p $(OBJDIR) 
$(BINDIR): 
	@mkdir -p $(BINDIR) 

# minimal objects implicit rule
$(OBJDIR)/cfl_%_min$(DOT_O): cfl_%.cpp $(OBJDIR)
	$(call FNCT_COMP_MIN,$<,$@)

# have my rti executabels (static version for configure target)
$(BINDIR)/rti2code$(DOT_EXE): $(SRCDIR)/rti2code.cpp $(MINFAUDES) $(BINDIR)   
	$(call FNCT_BUILD_MIN,$<,$@)

# merge rti files
$(INCLUDEDIR)/libfaudes.rti: $(BINDIR)/rti2code$(DOT_EXE)
	./bin/rti2code -merge $(RTIDEFS) $@

# have my auto register tools and produce includes
# note: we use .i as target since depend touches .h and .cpp
$(INCLUDEDIR)/rtiautoload.i: $(INCLUDEDIR)/libfaudes.rti $(BINDIR)/rti2code$(DOT_EXE) 
	./bin/rti2code $(PBP_RTIFLAT) $(INCLUDEDIR)/libfaudes.rti $(INCLUDEDIR)/rtiautoload


####################################
# Documentation: base
####################################

# configure reference processing
REF2HTML_CNAV ?= $(SRCDIR)/doxygen/faudes_navigation.include_fref
REF2HTML_CSS  ?= faudes.css
LUA2REF = $(CURDIR)/tools/lua2ref/lua2ref.pl
#LUA2REF = $(CURDIR)/bin/luafaudes $(CURDIR)/tools/lua2ref/lua2ref.lua

# all base documenation
BASEFREF = $(wildcard $(SRCDIR)/doxygen/*.fref)
BASEALL = $(BASEFREF) $(SRCDIR)/doxygen/faudes_navigation.include_fref
BASEHTML = $(foreach file,$(BASEFREF),$(DOCDIR)/$(basename $(notdir $(file))).html)
BASEHTML += $(DOCDIR)/index.html

# have a doc base directory: time stamp
$(DOCDIR): $(DOCDIR)/.tstamp

# have a doc base directory: populate
$(DOCDIR)/.tstamp: $(BASEALL) 
	- mkdir $(DOCDIR)
	- cp $(SRCDIR)/doxygen/faudes.css $(DOCDIR)
	touch $@

# have fref source directory: time stamp
$(REFSRCDIR): $(REFSRCDIR)/.tstamp $(DOCDIR)/.tstamp

# have fref source directory: populate
$(REFSRCDIR)/.tstamp: $(BASEFREF) $(DOCDIR)
	- mkdir $(REFSRCDIR)
	- cp $(BASEALL) $(REFSRCDIR)
	- cp $(REF2HTML_CNAV) $(REFSRCDIR)/faudes_navigation.include_fref
	touch $@

# copy index
$(DOCDIR)/index.html: $(DOCDIR)/faudes_about.html $(DOCDIR)
	cp -f  $< $@

# build doc run as script
doc-base: $(REFSRCDIR)


####################################
# Documentation: reference pages
####################################

# have reference documentation targets 
RTIHTML  = $(patsubst %.fref,$(REFDOCDIR)/%.html,$(notdir $(RTIFREF))) 
RTIHTML += $(REFDOCDIR)/index.html

# have fref source dir: time stamp
$(REFSRCDIR)/reference: $(REFSRCDIR)/reference/.tstamp

# have fref source dir: copy frefs  
$(REFSRCDIR)/reference/.tstamp: $(REFSRCDIR) $(RTIFREF) 
	- mkdir -p $(REFSRCDIR)/reference
	@echo copy frefs
	@ - cp -f $(RTIFREF) $(REFSRCDIR)/reference
	touch $@

# have dst directory: time stamp
$(REFDOCDIR): $(REFDOCDIR)/.tstamp

# have dst directory
$(REFDOCDIR)/.tstamp:
	- mkdir -p $(REFDOCDIR)
	touch $@

# registry main index
$(REFDOCDIR)/index.html: $(REFDOCDIR)/reference_index.html
	cp $^ $@ 

# plain copy
$(REFSRCDIR)/libfaudes.rti: $(INCLUDEDIR)/libfaudes.rti $(REFDOCDIR)
	cp $< $@
 
# target: copy fref source files
doc-reference: $(REFSRCDIR)/reference $(REFDOCDIR) $(REFSRCDIR)/libfaudes.rti 


####################################
# Documentaion: images 
####################################

# all images
IMAGES_ALL   = $(foreach dir,$(pluginstringI) $(SRCDIR)/doxygen/faudes_images,$(wildcard $(dir)/*)) 
IMAGES_FREF  = $(filter %.fref,$(IMAGES_ALL))
IMAGES_OTHER = $(filter-out %.fref,$(IMAGES_ALL))
IMAGES_HTML  = $(foreach file,$(IMAGES_FREF),$(IMGDOCDIR)/$(basename $(notdir $(file))).html)


# have destination directory
$(IMGDOCDIR): $(IMGDOCDIR)/.tstamp
$(IMGDOCDIR)/.tstamp:
	- mkdir -p $(IMGDOCDIR)
	touch $@

# have images fref source dir: time stamp
$(REFSRCDIR)/images: $(REFSRCDIR)/images/.tstamp

# copy images and fref to DOCDIR
$(REFSRCDIR)/images/.tstamp: $(REFSRCDIR) $(IMAGES_ALL) $(IMGDOCDIR)
	- mkdir -p $(REFSRCDIR)/images
	@echo copy images
	@ - cp -rf $(IMAGES_OTHER) $(IMGDOCDIR)
	@ - cp -rf $(IMAGES_FREF) $(REFSRCDIR)/images
	touch $@

# trigger (en-block copy if needed)
$(REFSRCDIR)/images/%.fref: $(REFSRCDIR)/images
	@echo trigger image copy    # need a recipie, otherwise the rule wont be applied

# target: make fref source files and copy images
doc-images: $(REFSRCDIR)/images


####################################
# Documentation lua tutorials
####################################

# if we have luabindings
ifeq (luabindings,$(findstring luabindings,$(FAUDES_PLUGINS)))

# all lua tutorials
LUATUTS  =$(foreach dir,$(pluginstringT),$(wildcard $(dir)/*.lua))
LUAFREF  = $(foreach file,$(LUATUTS),$(REFSRCDIR)/luafaudes/$(basename $(notdir $(file))).fref)
LUAFREF += $(REFSRCDIR)/luafaudes/faudes_luafaudes.fref
LUAFREF += $(REFSRCDIR)/luafaudes/faudes_luatech.fref
LUAFREF += $(REFSRCDIR)/luafaudes/faudes_luaext.fref
LUAHTML  = $(foreach file,$(LUAFREF),$(LUADOCDIR)/$(basename $(notdir $(file))).html)
LUAHTML += $(LUADOCDIR)/index.html

# have luafaudes doc dir: time stamp
$(LUADOCDIR): $(LUADOCDIR)/.tstamp

# have luafaudes doc dir: populate by defaults
$(LUADOCDIR)/.tstamp: 
	- mkdir -p $(LUADOCDIR)
	touch $@

# have luafaudes fref source dir: time stamp
$(REFSRCDIR)/luafaudes: $(REFSRCDIR)/luafaudes/.tstamp $(LUADOCDIR)

# have luafaudes fref source dir: copy tutorials
$(REFSRCDIR)/luafaudes/.tstamp: $(REFSRCDIR) $(LUATUTS) 
	- mkdir -p $(REFSRCDIR)/luafaudes
	@echo copy lua tutorials
	@ - cp -f $(LUATUTS) $(REFSRCDIR)/luafaudes
	touch $@

# process lua code to fref source  (trigger en-block if needed)
$(REFSRCDIR)/luafaudes/%.fref: $(REFSRCDIR)/luafaudes
	$(LUA2REF) $(subst .fref,.lua,$@) > $@

# copy static frefs
$(REFSRCDIR)/luafaudes/faudes_luafaudes.fref: plugins/luabindings/src/doxygen/faudes_luafaudes.fref
	cp -f  $< $@
$(REFSRCDIR)/luafaudes/faudes_luatech.fref: plugins/luabindings/src/doxygen/faudes_luatech.fref
	cp -f  $< $@
$(REFSRCDIR)/luafaudes/faudes_luaext.fref: plugins/luabindings/src/doxygen/faudes_luaext.fref
	cp -f  $< $@

# copy index
$(LUADOCDIR)/index.html: $(LUADOCDIR)/faudes_luafaudes.html
	cp -f  $< $@

# target: make fref source files
doc-luafaudes: $(REFSRCDIR)/luafaudes 
	make $(LUAFREF) 
	cp $(LBP_REPLDIR)/luafaudes_repl.html $(LUADOCDIR)
	cp $(LBP_REPLDIR)/LICENSE $(LUADOCDIR)
	cp $(LBP_REPLDIR)/*.css $(LUADOCDIR)
	cp $(LBP_REPLDIR)/*.lua $(LUADOCDIR)
	cp $(LBP_REPLDIR)/*.js $(LUADOCDIR)

# if we dont have luabindings
else

# static dummies
LUAFREF  = $(REFSRCDIR)/luafaudes/faudes_luafaudes.fref
LUAFREF += $(REFSRCDIR)/luafaudes/faudes_luatech.fref
LUAFREF += $(REFSRCDIR)/luafaudes/faudes_luaext.fref
LUAHTML  = $(foreach file,$(LUAFREF),$(LUADOCDIR)/$(basename $(notdir $(file))).html)
LUAHTML += $(LUADOCDIR)/index.html

# have luafaudes doc dir: time stamp
$(LUADOCDIR): $(LUADOCDIR)/.tstamp

# have luafaudes doc dir: populate by defaults
$(LUADOCDIR)/.tstamp: 
	- mkdir -p $(LUADOCDIR)
	touch $@

# have luafaudes fref source dir: time stamp
$(REFSRCDIR)/luafaudes: $(REFSRCDIR)/luafaudes/.tstamp $(LUADOCDIR)

# have luafaudes fref source dir: copy tutorials
$(REFSRCDIR)/luafaudes/.tstamp: $(LUATUTS) 
	- mkdir -p $(REFSRCDIR)/luafaudes
	@echo copy tutorial
	@ - cp -f $(LUATUTS) $(REFSRCDIR)/luafaudes
	touch $@

# copy static frefs
$(REFSRCDIR)/luafaudes/faudes_%.fref: $(SRCDIR)/doxygen/faudes_noluafaudes.fref $(REFSRCDIR)/luafaudes  
	cp -f  $< $@

# copy index
$(LUADOCDIR)/index.html: $(LUADOCDIR)/faudes_luafaudes.html
	cp -f  $< $@

# target: copy fref source files
doc-luafaudes: $(REFSRCDIR)/luafaudes 
	make $(LUAFREF) 

# end of luabindings dummy
endif



####################################
# Documentaion: compile frefs
####################################

# note: html is generated by ref2html via flxinstall

# have my tools (static version for configure target)
$(BINDIR)/flxinstall$(DOT_EXE): $(SRCDIR)/flxinstall.cpp $(MINFAUDES)   
	$(call FNCT_BUILD_MIN,$<,$@)

# have my tools (static version for configure target)
$(BINDIR)/ref2html$(DOT_EXE): $(SRCDIR)/ref2html.cpp $(MINFAUDES)   
	$(call FNCT_BUILD_MIN,$<,$@)


# tools target
reftools: $(BINDIR)/ref2html$(DOT_EXE) $(BINDIR)/flxinstall$(DOT_EXE)


# flxinstall command with luabindings
ifeq (luabindings,$(findstring luabindings,$(FAUDES_PLUGINS)))
FLXFILES = $(wildcard stdflx/*.flx)
FLXCMD = bin/flxinstall -tcss $(REF2HTML_CSS) -i $(FLXFILES) .
# flxinstall command without luabindings
else
FLXCMD = bin/flxinstall -tcss $(REF2HTML_CSS) -r .
endif

# user target
doc-fref: reftools $(REFSRCDIR)/libfaudes.rti $(REFSRCDIR) $(REFSRCDIR)/images $(BASEFREF) $(LUAFREF) $(RTIFREF)
	$(FLXCMD)



####################################
# Documentation: overall doc target
####################################

doc-clean: 
	- rm -rf $(DOCDIR)
	- mkdir $(DOCDIR)

#convert command
REF2HTMLCMD = ./bin/ref2html -rti $(REFSRCDIR)/libfaudes.rti -css $(REF2HTML_CSS) -cnav $(REFSRCDIR)/faudes_navigation.include_fref -rel ../ -css doxygen.css 

# build doc: run as script
docs: reftools rtitools doc-images doc-base doc-luafaudes doc-reference includes 
	- mkdir -p $(DOXDOCDIR)
	$(REF2HTMLCMD) -doxheader $(DOXDOCDIR)/doxygen_header.html
	$(REF2HTMLCMD) -doxfooter $(DOXDOCDIR)/doxygen_footer.html
	cp $(SRCDIR)/doxygen/doxygen.xml $(DOXDOCDIR)
	@echo running doxygen
	( cat $(SRCDIR)/doxygen/doxygen.conf ; \
              echo "INPUT += $(VPATH)" ; \
	      echo "INPUT += $(SRCDIR)/doxygen/doxygen_groups.h" ; \
	      echo "INCLUDE_PATH += $(INCLUDEDIR)" ; \
              echo "EXAMPLE_PATH += $(VPATH)" ; \
              echo "INCLUDE_PATH += $(SRCDIR)/doxygen" ; \
              echo "PROJECT_NAME = \"libFAUDES $(FAUDES_VERSION)\"" ; \
        ) | $(DOXYGEN) -
	cp $(SRCDIR)/doxygen/doxygen.css $(DOXDOCDIR)
	cat $(SRCDIR)/doxygen/faudes.css >> $(DOXDOCDIR)/doxygen.css	
	- cp $(DOXDOCDIR)/main.html $(DOXDOCDIR)/index.html
	@echo processing fref to html
	make doc-fref


####################################
# (Semi-) Automatic generation of dependencies
####################################

# explicit target
depend: $(SOURCES) includes
	touch $(INCLUDEDIR)/rtiautoload.h
	touch $(INCLUDEDIR)/rtiautoload.cpp
	@echo update dependencies
	@echo "# libFAUDES build dependencies" > $(DEPEND)
	@echo "# - do not edit this file manually" >> $(DEPEND)
	@echo "# - see main Makefile for documentation" >> $(DEPEND)
	@ $(CXX) -MM $(CFLAGS) $(SOURCES) | sed 's/\(^.*:\)/$(OBJDIR)\/\1/' >> $(DEPEND)

# dont do this automatically
$(DEPEND):

####################################
# Implicit default rules 
####################################

# .cpp -> .o  (trust automatic dependencies)
$(OBJDIR)/%$(DOT_O): %.cpp 
	$(call FNCT_COMP_LIB,$<,$@)

# .h -> include/.h
$(INCLUDEDIR)/%.h: %.h
	$(call FNCT_COPY,$<,$@)


# precompile headers (not functional with g++ 4.2.1 as found in osx 10.7)
precompile-headers: $(HEADERS:%=$(INCLUDEDIR)/%.gch) 
$(INCLUDEDIR)/%.h.gch: $(INCLUDEDIR)/%.h
	$(call FNCT_COMP_LIB,$<,$@)


####################################
# Library targets
####################################


$(LIBFAUDES): $(OBJECTS) $(OBJECTSEXT)
ifeq ($(SHARED),yes)
	$(LXX) $(DSOOPTS) $(call FNCT_FIXDIRSEP,$^) $(LDFLAGS) $(LNKLIBS) $(LOUTOPT)$(call FNCT_FIXDIRSEP,$@)
else
	$(AR) $(AOUTOPT)$@ $(call FNCT_FIXDIRSEP,$^)
endif

$(MINFAUDES): $(OBJECTSMIN)
	$(AR) $(AOUTOPT)$@ $(call FNCT_FIXDIRSEP,$^)



####################################
# Executables
####################################

# compile and link applications 

$(BINDIR)/%$(DOT_EXE): %.cpp $(LIBFAUDES)
	$(call FNCT_COMP_APP,$<,$(OBJDIR)/$*$(DOT_O))
	$(call FNCT_LINK_APP,$(OBJDIR)/$*$(DOT_O),$@)
	$(call FNCT_POST_APP,$@)


####################################
# Test cases
####################################

# Protocols incl path
PROTODIRS = ./tutorial/data $(patsubst %,%/data,$(pluginstringT))
PROTOCOLS = $(foreach dir,$(PROTODIRS),$(wildcard $(dir)/*_cpp.prot)) 
PROTOCOLS += $(foreach dir,$(PROTODIRS),$(wildcard $(dir)/*_lua.prot)) 
PROTOCOLS += $(foreach dir,$(PROTODIRS),$(wildcard $(dir)/*_py.prot)) 

# Formal targets
TESTTARGETS = $(patsubst %,TESTCASE%,$(PROTOCOLS))

# tools
ABSLUAFAUDES = $(CURDIR)/bin/luafaudes
ABSFLXINSTALL = $(CURDIR)/bin/flxinstall

# Conversion functions
FNCT_PROTOCOL = $(patsubst TESTCASE%,%,$(1))
FNCT_LUASCRIPT = $(patsubst %_lua.prot,%.lua,$(notdir $(call FNCT_PROTOCOL,$(1))))
FNCT_PYSCRIPT = $(patsubst %_py.prot,%.py,$(notdir $(call FNCT_PROTOCOL,$(1))))
FNCT_CPPBIN = $(patsubst %_cpp.prot,%,$(notdir $(call FNCT_PROTOCOL,$(1))))
FNCT_WORKDIR = $(patsubst %/data/,%,$(dir $(call FNCT_PROTOCOL,$(1))))
FNCT_TMPPROT = $(patsubst %,tmp_%,$(notdir $(call FNCT_PROTOCOL,$(1))))

# platform dependant script (... first experiments ...)
ifeq ($(findstring _win,$(FAUDES_PLATFORM)),)
FNCT_RUNCPPBIN = cd $(call FNCT_WORKDIR,$@) ; ./$(call FNCT_CPPBIN,$@) &> /dev/null
FNCT_RUNLUASCRIPT = cd $(call FNCT_WORKDIR,$@) ; $(ABSLUAFAUDES) $(call FNCT_LUASCRIPT,$@) &> /dev/null
FNCT_RUNPYSCRIPT  = cd $(call FNCT_WORKDIR,$@) ; $(PYTHON) $(call FNCT_PYSCRIPT,$@) &> /dev/null
FNCT_DIFFPROT = $(DIFF) $(call FNCT_PROTOCOL,$@) $(call FNCT_WORKDIR,$@)/$(call FNCT_TMPPROT,$@)
else
FNCT_RUNCPPBIN = $(call FNCT_FIXDIRSEP,cd $(call FNCT_WORKDIR,$(1)) & ./$(call FNCT_CPPBIN,$(1)) > NUL 2>&1 )
FNCT_RUNLUASCRIPT = $(call FNCT_FIXDIRSEP,cd $(call FNCT_WORKDIR,$@) & $(ABSLUAFAUDES) $(call FNCT_LUASCRIPT,$@) > NUL 2>&1)
FNCT_RUNPYSCRIPT = @$(ECHO) "skipping test case" $(call FNCT_PYSCRIPT,$@) "[no Python tests on Windows]"
FNCT_DIFFPROT = $(DIFF) $(call FNCT_FIXDIRSEP,$(call FNCT_PROTOCOL,$@) $(call FNCT_WORKDIR,$@)/$(call FNCT_TMPPROT,$@))
endif


# validate lua extensions (currently unix only)
TESTTARGETSX = $(patsubst %,TESTCASE%,$(notdir $(wildcard stdflx/*.flx))) 
TESTTARGETS += $(TESTTARGETSX)


# lua test cases
%_lua.prot: 
ifeq (luabindings,$(findstring luabindings,$(FAUDES_PLUGINS)))
	@echo running test case $(call FNCT_LUASCRIPT,$@)
	@- $(call FNCT_RUNLUASCRIPT,$@)
	@ $(call FNCT_DIFFPROT,$@)
else
	@echo skipping test case $(call FNCT_LUASCRIPT,$@) [no Lua bindings configured]
endif

# python test cases
%_py.prot: 
ifeq (pybindings,$(findstring pybindings,$(FAUDES_PLUGINS)))
	@echo running test case $(call FNCT_PYSCRIPT,$@)
	@- $(call FNCT_RUNPYSCRIPT,$@)
	@ $(call FNCT_DIFFPROT,$@)
else
	@echo skipping test case $(call FNCT_PYSCRIPT,$@) [no Python bindings configured]
endif

# cpp test cases
%_cpp.prot: 
	@echo running test case $(call FNCT_CPPBIN,$@)
	@- $(call FNCT_RUNCPPBIN,$@)
	@ $(call FNCT_DIFFPROT,$@)

# have temp dir
tmp_valext: 
	@- mkdir tmp_valext

# validate lua-extension 
TESTCASE%.flx: tmp_valext
ifneq (_win,$(findstring _win,$(FAUDES_PLATFORM)))
ifeq (luabindings,$(findstring luabindings,$(FAUDES_PLUGINS)))
	@echo running test case $(patsubst TESTCASE%,%,$@)
	@- rm -rf tmp_valext/data  ; rm -f tmp_valext/*
	@cd tmp_valext; $(ABSFLXINSTALL) -tbin ../bin -t ../stdflx/$(patsubst TESTCASE%,%,$@) . &> /dev/null
else
	@echo skipping test case $(patsubst TESTCASE%,%,$@) [no Lua bindings configured]
endif
endif

# all tests
test: tutorial $(TESTTARGETS) 
	@echo " ============================== " 
	@echo "libFAUDES-make: test cases: done" 
	@echo " ============================== " 


# more test cases: extensions





####################################
# Makefile debugging
####################################

report-platform:
	@echo " ============================== " 
	@echo "libFAUDES-make: platform	" [$(FAUDES_PLATFORM)] [$(FAUDES_LINKING)]
	@echo " ============================== " 

report-targets:
	@echo " ============================== " 
	@echo "libFAUDES-make: targets " $(DEFAULTTARGETS)
	@echo " ============================== "

report-test:
	@echo $(ECHOE)


### all phony targets
.PHONY : doc rti bin clean dist-clean package configure includes


###############################
# note:
#   $@ = target
#   $^ = prerequisites
#   $< = first prerequisite
###############################
