#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Assume-se uma distribuição Linux como sistema operacional padrão.
# No Windows, o build usa o MSYS2 (ambiente mingw64) e deve ser chamado a partir de um shell sh (MSYS2 ou Git Bash).
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#O compilador
COMPILER ?= g++
# Comando para remover pastas
RMDIR = rm -rf
#Comando para remover arquivos
RM = rm -f

#"Flags" para a geração automática de dependências
DEP_FLAGS = -M -MT $@  -MT $(BIN_PATH)/$(*F).o -MP -MF $@
#Bibliotecas a serem linkadas
LIBS = -lm

PKG_CONFIG ?= pkg-config
SDL_CFLAGS :=
SDL_INC_PATHS :=
LINK_PATH :=

#Caminho dos includes
INC_PATHS = $(addprefix -I,$(INC_PATH)) $(SDL_CFLAGS) $(addprefix -I,$(SDL_INC_PATHS))

#Diretivas de compilação
FLAGS = -std=c++11 -Wall -g -pedantic -Wextra -Wno-unused-parameter -Werror=init-self
#Diretivas extras para debug
DFLAGS = -ggdb -O0 -DDEBUG
#Diretivas extras para release
RFLAGS = -O3 -mtune=native

INC_PATH = $(sort $(wildcard include/*/)) include/
SRC_PATH = $(sort $(wildcard src/*/)) src/
BIN_PATH = build/bin
DEP_PATH = build/dep
BUILD_PATH = build/
DIST_PATH = dist/yawara

# Uma lista de arquivos por extensão:
CPP_FILES = $(wildcard $(addsuffix *.cpp, $(SRC_PATH)))
INC_FILES = $(wildcard $(addsuffix *.h, $(INC_PATH)))
FILE_NAMES = $(sort $(notdir $(CPP_FILES:.cpp=)) $(notdir $(INC_FILES:.h=)))
DEP_FILES = $(addprefix $(DEP_PATH)/,$(addsuffix .d,$(FILE_NAMES)))
OBJ_FILES = $(addprefix $(BIN_PATH)/,$(notdir $(CPP_FILES:.cpp=.o)))

# Nome do executável
EXEC = yawara
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Caso o sistema seja Windows (MSYS2 mingw64)
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ifeq ($(OS),Windows_NT)

# Instalação do MSYS2 mingw64 que contém o g++ e as bibliotecas SDL2.
# Use SDL2_PREFIX=<caminho> para apontar outra instalação.
SDL2_PREFIX ?= C:/msys64/mingw64

SDL_INC_PATHS := $(SDL2_PREFIX)/include
LINK_PATH := -L$(SDL2_PREFIX)/lib
FLAGS += -D_USE_MATH_DEFINES
RELEASE_LDFLAGS = -mwindows
DEBUG_LDFLAGS = -mconsole
LIBS := -lmingw32 -lSDL2main -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf $(LIBS)

#nome do executável
EXEC := $(EXEC).exe

# Usa o g++ da mesma instalação das bibliotecas, para não misturar runtimes (ucrt64 x mingw64).
PREFIX_GXX := $(wildcard $(SDL2_PREFIX)/bin/g++.exe)
ifneq ($(PREFIX_GXX),)
COMPILER := $(PREFIX_GXX)
endif

else

UNAME_S := $(shell uname -s)

#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Caso o sistema seja Mac
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ifeq ($(UNAME_S), Darwin)
LIBS = -lm -framework SDL2 -framework SDL2_image -framework SDL2_mixer -framework SDL2_ttf
else
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Caso o sistema seja Linux: usa pkg-config e, na falta dele, os caminhos padrão
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SDL_CFLAGS := $(shell $(PKG_CONFIG) --cflags sdl2 SDL2_image SDL2_mixer SDL2_ttf 2>/dev/null)
ifneq ($(SDL_CFLAGS),)
LIBS += $(shell $(PKG_CONFIG) --libs sdl2 SDL2_image SDL2_mixer SDL2_ttf 2>/dev/null)
else
LIBS += -lSDL2 -lSDL2_image -lSDL2_mixer -lSDL2_ttf
endif
endif
endif
################################################################################################################################################################################

.PRECIOUS: $(DEP_FILES)
.PHONY: all release debug clean folders run dist dlls help

#Regra geral
all: release

#Gera o executável
$(EXEC): $(OBJ_FILES)
	$(COMPILER)  -o $@ $^ $(LINK_PATH) $(LIBS) $(FLAGS) $(LDFLAGS)
ifeq ($(OS),Windows_NT)
	@$(MAKE) --no-print-directory dlls
endif

#Gera os arquivos objetos
$(BIN_PATH)/%.o: $(DEP_PATH)/%.d | folders
	$(COMPILER) $(INC_PATHS) $(subst //,/,$(filter %/$*.cpp, $(CPP_FILES))) -c $(FLAGS) -o $@

.SECONDEXPANSION:
#Gera os arquivos de dependência
$(DEP_PATH)/%.d: $$(filter $$(addsuffix $$*.cpp, $$(SRC_PATH)), $$(CPP_FILES)) | folders
	$(COMPILER) $(INC_PATHS) $(subst //,/,$(filter %/$*.cpp, $(CPP_FILES))) $(DEP_FLAGS) $(FLAGS)

clean:
	-$(RMDIR) $(BUILD_PATH) dist
	-$(RM) $(EXEC) *.dll

release: FLAGS += $(RFLAGS)
release: LDFLAGS += $(RELEASE_LDFLAGS)
release: $(EXEC)

debug: FLAGS += $(DFLAGS)
debug: LDFLAGS += $(DEBUG_LDFLAGS)
debug: $(EXEC)

folders:
	@mkdir -p $(DEP_PATH) $(BIN_PATH)

# Copia para a raiz as DLLs (SDL2 e dependências) que o executável carrega, para rodar sem alterar o PATH.
dlls:
ifeq ($(OS),Windows_NT)
	@PATH="$$(cygpath -u '$(SDL2_PREFIX)')/bin:$$PATH" ldd $(EXEC) \
		| awk '{print $$3}' | grep -i "^$$(cygpath -u '$(SDL2_PREFIX)')/bin/" \
		| xargs -I{} cp -u {} .
	@echo "DLLs copiadas para a raiz do projeto."
endif

#Executa o jogo
run: $(EXEC)
	./$(EXEC)

#Gera uma pasta autocontida com executável, DLLs e assets
dist: $(EXEC)
	@mkdir -p $(DIST_PATH)
	cp $(EXEC) $(DIST_PATH)/
ifeq ($(OS),Windows_NT)
	cp *.dll $(DIST_PATH)/
endif
	cp -r assets $(DIST_PATH)/
	@echo "Pacote gerado em $(DIST_PATH)"

#Regra para debug
print-% : ; @echo $* = $($*)

help:
	@echo "Available targets:"
	@echo "- release:  Builds the release version (default)"
	@echo "- debug:    Builds the debug version (console on Windows)"
	@echo "- run:      Builds and runs the game"
	@echo "- dist:     Creates dist/yawara with executable, DLLs and assets"
	@echo "- clean:    Cleans the generated files"
	@echo "- SDL2_PREFIX=<path>  Custom MSYS2 mingw64 prefix on Windows (default C:/msys64/mingw64)"
	@echo "- PKG_CONFIG=<tool>   Custom pkg-config executable on Linux"

.SECONDEXPANSION:
-include $$(DEP_FILES)
