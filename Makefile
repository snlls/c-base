ARCH ?= x64
CC ?= gcc
LINKER ?= $(CC)
STD = -std=c11
PREFIX ?= /usr/local

SRC_DIR=src
OBJ_DIR=build
SOURCES=$(wildcard $(SRC_DIR)/*.c)
OBJECTS=$(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)

EXE=exe

CFLAGS :=  $(STD) -DDEBUG -g -Wall -Iinclude -Wno-unused-function -Wno-unused-variable

release: CFLAGS := $(filter-out -DDEBUG -g, $(CFLAGS))


SYSLIBS=

LDFLAGS += $(foreach lib, $(SYSLIBS), $(shell pkg-config --libs $(lib)))
CFLAGS += $(foreach lib, $(SYSLIBS), $(shell pkg-config --cflags $(lib)))

SLIBS := $(wildcard slib/*)
ALIBS := $(wildcard slib/*/$(ARCH)/*.a)

#$(info $$CFLAGS is [${CFLAGS}])

CFLAGS += $(foreach lib, $(SLIBS), -Islib/$(lib))

LIBSOURCES += $(wildcard slib/*/*.c)
OBJECTS += $(LIBSOURCES:slib/%.c=$(OBJ_DIR)/%.o)

DEPS=$(OBJECTS:.o=.d)


ifeq ($(CC),tcc)
	DEPFLAGS:=-MD
endif

ifeq ($(CC),gcc)
	DEPFLAGS:=-MD -MP
endif

ifeq ($(CC),clang)
	DEPFLAGS:=-MD -MP
endif


.PHONY: all

all: $(EXE)

release: $(EXE)

run:
	@./$(EXE)

install: $(EXE)
	cp $(EXE) "$(PREFIX)/bin/"

uninstall:
	rm -f "$(PREFIX)/bin/$(EXE)"

$(EXE): $(OBJECTS)
	$(LINKER) $(LDFLAGS) $^ $(ALIBS) $(LDLIBS) -o $@

$(OBJ_DIR):
	@mkdir -p $@

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c $(OBJ_DIR)/%.d | $(OBJ_DIR)
	$(CC) -fPIC $(CFLAGS) $(DEPFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: slib/%.c $(OBJ_DIR)/%.d
	@mkdir -p $(@D)
	$(CC) -fPIC $(CFLAGS) $(DEPFLAGS) -c $< -o $@


.PHONY: clean

clean:
	rm -rf $(OBJ_DIR)/*
	rm -f $(EXE)

$(DEPS):


#-include $(OBJECTS:.o=.d)
include $(wildcard $(DEPS))
