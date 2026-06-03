#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Assume-se uma distribuição Linux como sistema operacional padrão
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#O compilador
COMPILER ?= g++
# Comando para remover pastas
RMDIR = rm -rdf
#Comando para remover arquivos
RM = rm -f

#"Flags" para a geração automática de dependências
DEP_FLAGS = -M -MT $@  -MT $(BIN_PATH)/$(*F).o -MP -MF $@
#Bibliotecas a serem linkadas
LIBS = -lm

# SDL2 options: use SDL2_PREFIX or SDL_PREFIX to override autodetection
SDL2_PREFIX ?= $(SDL_PREFIX)
SDL_PATHS ?= $(SDL2_PREFIX) C:/msys64/mingw64 C:/SDL2/x86_64-w64-mingw32 C:/Tools/msys64/mingw64 /usr/local /usr
PKG_CONFIG ?= pkg-config
SDL_CFLAGS ?=
SDL_LIBS ?=
LINK_PATH ?=

#Caminho dos includes
INC_PATHS = $(addprefix -I,$(INC_PATH)) $(SDL_CFLAGS) $(addprefix -I,$(SDL_INC_PATHS))

#Diretivas de compilação
FLAGS = -std=c++11 -Wall -g -pedantic -Wextra -Wno-unused-parameter -Werror=init-self
#Diretivas extras para debug
DFLAGS = -ggdb -O0 -DDEBUG
#Diretivas extras para release
RFLAGS = -O3 -mtune=native

INC_PATH = $(sort $(dir $(wildcard include/*/*/)))
INC_PATH += include/
SRC_PATH = $(sort $(dir $(wildcard src/*/*/)))
SRC_PATH += src/
BIN_PATH = build/bin
DEP_PATH = build/dep
BUILD_PATH = build/

# Uma lista de arquivos por extensão:
CPP_FILES = $(wildcard $(addsuffix *.cpp, $(SRC_PATH)))
INC_FILES = $(wildcard $(addsuffix *.h, $(INC_PATH)))
FILE_NAMES = $(sort $(notdir $(CPP_FILES:.cpp=)) $(notdir $(INC_FILES:.h=)))
DEP_FILES = $(addprefix $(DEP_PATH)/,$(addsuffix .d,$(FILE_NAMES)))
OBJ_FILES = $(addprefix $(BIN_PATH)/,$(notdir $(CPP_FILES:.cpp=.o)))

# Nome do executável
EXEC = yawara
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Caso o sistema seja Windows
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ifeq ($(OS),Windows_NT)

#Comando para remover um diretório recursivamente
RMDIR = cmd /C rmdir /s /q

#comando para deletar um único arquivo
RM = cmd /C del /q


# Use the shared SDL_PATHS setting above and add include paths for Windows builds.
SDL_INC_PATHS += $(addsuffix /include,$(SDL_PATHS))
LINK_PATH := $(addprefix -L,$(addsuffix /lib,$(SDL_PATHS)))
FLAGS += -mwindows
FLAGS += -D_USE_MATH_DEFINES
DFLAGS += -mconsole
SDL_LIBS := -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf
LIBS := -lmingw32 -lSDL2main $(SDL_LIBS) $(LIBS)

#nome do executável
EXEC := $(EXEC).exe

# Detect MSYS2 mingw-w64 compiler (prefer it on Windows if available)
MSYS_MINGW_GXX := $(wildcard C:/msys64/mingw64/bin/x86_64-w64-mingw32-g++.exe)
ifeq ($(MSYS_MINGW_GXX),)
MSYS_MINGW_GXX := $(wildcard C:/msys64/mingw64/bin/g++.exe)
endif
ifneq ($(MSYS_MINGW_GXX),)
COMPILER := $(MSYS_MINGW_GXX)
endif

else

UNAME_S := $(shell uname -s)

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Caso o sistema seja Mac
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ifeq ($(UNAME_S), Darwin)
LIBS = -lm -framework SDL2 -framework SDL2_image -framework SDL2_mixer -framework SDL2_ttf
else
# Linux/Unix fallback: prefer pkg-config, use SDL_PATHS if not available
PKG_CONFIG_PATH := $(shell command -v $(PKG_CONFIG) 2>/dev/null)
ifneq ($(PKG_CONFIG_PATH),)
SDL_CFLAGS := $(shell $(PKG_CONFIG) --cflags sdl2 SDL2_image SDL2_mixer SDL2_ttf 2>/dev/null)
SDL_LIBS := $(shell $(PKG_CONFIG) --libs sdl2 SDL2_image SDL2_mixer SDL2_ttf 2>/dev/null)
endif
ifneq ($(SDL_CFLAGS),)
LIBS += $(SDL_LIBS)
else
SDL_INC_PATHS ?= $(addsuffix /include,$(SDL_PATHS))
LINK_PATH ?= $(addprefix -L,$(addsuffix /lib,$(SDL_PATHS)))
LIBS += -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf
endif
endif
endif
################################################################################################################################################################################

.PRECIOUS: $(DEP_FILES)
.PHONY: release debug clean folders help

#Regra geral
all:	$(EXEC)

#Gera o executável
$(EXEC): $(OBJ_FILES)
	$(COMPILER)  -o $@ $^ $(LINK_PATH) $(LIBS) $(FLAGS)

#Gera os arquivos objetos
$(BIN_PATH)/%.o: $(DEP_PATH)/%.d | folders
	$(COMPILER) $(INC_PATHS) $(subst //,/,$(filter %/$*.cpp, $(CPP_FILES))) -c $(FLAGS) -o $@

.SECONDEXPANSION:
#Gera os arquivos de dependência
$(DEP_PATH)/%.d: $$(filter $$(addsuffix $$*.cpp, $$(SRC_PATH)), $$(CPP_FILES)) | folders
	$(COMPILER) $(INC_PATHS) $(subst //,/,$(filter %/$*.cpp, $(CPP_FILES))) $(DEP_FLAGS) $(FLAGS)

clean:
		-$(RMDIR) $(DEP_PATH)
		-$(RMDIR) $(BIN_PATH)
		-$(RMDIR) $(BUILD_PATH)
		-$(RM) $(EXEC)

release: FLAGS += $(RFLAGS)
release: $(EXEC)

debug: FLAGS += $(DFLAGS)
debug: $(EXEC)

folders:
ifeq ($(OS), Windows_NT)
	@for %%D in ($(DEP_PATH) $(BIN_PATH) $(INC_PATH) $(SRC_PATH)) do @if not exist "%%D" mkdir "%%D"
else
	@mkdir -p $(DEP_PATH) $(BIN_PATH) $(INC_PATH) $(SRC_PATH)
endif

#Regra para debug
print-% : ; @echo $* = $($*)

help:
ifeq ($(OS), Windows_NT)
	@echo.
endif
	@echo Available targets:
	@echo - release:	Builds the release version
	@echo - debug:		Builds the debug version
	@echo - clean:		Cleans the generated files
	@echo - folders:	Generates project directories
	@echo - help:		Shows this help
	@echo - SDL2_PREFIX=<path> Use custom SDL2 installation prefix on Windows or Linux
	@echo - PKG_CONFIG=<tool> Use a custom pkg-config executable on Linux
ifeq ($(OS), Windows_NT)
	@echo.
endif

.SECONDEXPANSION:
-include $$(DEP_FILES)
