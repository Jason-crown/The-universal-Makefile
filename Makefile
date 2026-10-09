
# ============================================================
# Universal C / C++ Makefile
# Supports GNU Make, GCC, G++, Clang, and Clang++
# ============================================================

# ---------- Project settings ----------

TARGET      ?= app
BUILD_DIR   ?= build
SRC_DIRS    ?= . src
INCLUDE_DIRS ?= include

# ---------- Toolchain ----------

CC          ?= gcc
CXX         ?= g++
CFLAGS      ?= -Wall -Wextra -Wpedantic -std=c11
CXXFLAGS    ?= -Wall -Wextra -Wpedantic -std=c++17
CPPFLAGS    ?=
LDFLAGS     ?=
LDLIBS      ?=

# ---------- Build configuration ----------

# Usage: make BUILD=debug
BUILD       ?= release

ifeq ($(BUILD),debug)
    CFLAGS   += -g -O0
    CXXFLAGS += -g -O0
else
    CFLAGS   += -O2
    CXXFLAGS += -O2
endif

# ---------- Automatically discover source files ----------

rwildcard = $(foreach d,$(wildcard $1*),\
             $(call rwildcard,$d/,$2) $(filter $2,$d))

C_SOURCES := $(foreach dir,$(SRC_DIRS),\
              $(call rwildcard,$(dir)/,*.c))

CPP_SOURCES := $(foreach dir,$(SRC_DIRS),\
                $(call rwildcard,$(dir)/,*.cpp) \
                $(call rwildcard,$(dir)/,*.cc) \
                $(call rwildcard,$(dir)/,*.cxx))

# Remove duplicates
C_SOURCES   := $(sort $(C_SOURCES))
CPP_SOURCES := $(sort $(CPP_SOURCES))

# ---------- Include directories ----------

CPPFLAGS += $(foreach dir,$(INCLUDE_DIRS),-I$(dir))

# ---------- Object files and dependencies ----------

C_OBJECTS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(C_SOURCES))

CPP_OBJECTS := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(filter %.cpp,$(CPP_SOURCES))) \
               $(patsubst %.cc,$(BUILD_DIR)/%.o,$(filter %.cc,$(CPP_SOURCES))) \
               $(patsubst %.cxx,$(BUILD_DIR)/%.o,$(filter %.cxx,$(CPP_SOURCES)))

OBJECTS := $(C_OBJECTS) $(CPP_OBJECTS)
DEPS    := $(OBJECTS:.o=.d)

# Use the C++ linker if the project contains C++ files
ifneq ($(strip $(CPP_SOURCES)),)
    LINKER := $(CXX)
else
    LINKER := $(CC)
endif

# ---------- Default target ----------

.DEFAULT_GOAL := all

.PHONY: all run clean debug release rebuild list help

all: $(TARGET)

# ---------- Linking ----------

$(TARGET): $(OBJECTS)
	$(LINKER) $(LDFLAGS) $(OBJECTS) $(LDLIBS) -o $@

# ---------- Compilation ----------

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR)/%.o: %.cc
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MMD -MP -c $< -o $@

$(BUILD_DIR)/%.o: %.cxx
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -MMD -MP -c $< -o $@

# ---------- Include generated header dependencies ----------

-include $(DEPS)

# ---------- Convenience targets ----------

run: $(TARGET)
	./$(TARGET)

debug:
	$(MAKE) BUILD=debug all

release:
	$(MAKE) BUILD=release all

rebuild: clean all

clean:
	$(RM) -r $(BUILD_DIR)
	$(RM) $(TARGET)

list:
	@echo "C sources:"
	@echo "$(C_SOURCES)"
	@echo "C++ sources:"
	@echo "$(CPP_SOURCES)"
	@echo "Objects:"
	@echo "$(OBJECTS)"

help:
	@echo "Available targets:"
	@echo "  make              Build the project"
	@echo "  make run          Build and run"
	@echo "  make debug        Build with debug settings"
	@echo "  make release      Build with release settings"
	@echo "  make rebuild      Clean and rebuild"
	@echo "  make clean        Remove build files"
	@echo "  make list         Show discovered source files"
	@echo "  make help         Show this help"