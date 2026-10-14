# Plano: tornar Yawara compilável e executável novamente

## Contexto

Yawara é um jogo em C++11/SDL2 feito em 2019 na UnB. Ele não compila nem executa no Windows atual por quatro causas, todas confirmadas por um build de teste numa cópia temporária:

1. **Erro de compilação:** a linha `include/resources/Text.h:51` declara `uint count;`. O tipo `uint` é um typedef da glibc e não existe no MinGW. Com essa linha trocada, os 51 `.cpp` compilam, o link funciona e o jogo rodou 10 s na tela de título sem erros.
2. **Makefile quebrado no Windows:** o alvo `folders` usa sintaxe do `cmd` (`for %%D in (...)`), mas o `make` do MSYS2 executa `/usr/bin/sh`. O `RMDIR`/`RM` usam `cmd /C`. O `wildcard include/*/*/` captura os diretórios vazios criados por uma tentativa anterior (`include/c++/15.2.0/`, `include/python3.14/...`), e o alvo `folders` recria esses diretórios a cada build.
3. **Lixo não versionado no repositório:** a pasta `include/` tem 24 diretórios vazios do toolchain; `bin/` tem 173 executáveis e DLLs do ucrt64; também há `lib/`, `build/` e um `yawara.exe` de 02/06/2026.
4. **Runtimes misturados:** o PATH aponta para `C:\msys64\ucrt64\bin` (gcc 15.2, sem SDL2), mas a SDL2 só está instalada em `C:\msys64\mingw64` (gcc 16.1, runtime msvcrt). Um `.exe` gerado no mingw64 que carregue a `libstdc++-6.dll` do ucrt64 falha ao iniciar.

**Resultado esperado:** `make` compila sem erros nem warnings no Windows (MSYS2 mingw64) e no Linux. `make dist` gera uma pasta autocontida que abre com duplo clique. O CI do GitHub valida os dois sistemas. As 3 fases foram jogadas do início ao fim.

## Decisões tomadas

| Tema | Decisão | Custo aceito |
|---|---|---|
| Plataformas | Windows e Linux | O ramo macOS do Makefile continua no arquivo, mas fica sem verificação. |
| Toolchain Windows | MSYS2 **mingw64**, já instalado | O runtime msvcrt é legado. O build deve rodar no shell mingw64, ou com `C:\msys64\mingw64\bin` à frente no PATH. |
| Build | Corrigir o Makefile existente | A lógica por sistema operacional continua manual. |
| Lixo local | Apagar `bin/`, `lib/`, `build/`, `yawara.exe` e os diretórios vazios em `include/` | É irreversível, porque nada disso está no git. |
| Linux | Validado por GitHub Actions | O CI só verifica a compilação; o jogo não é executado com janela. |
| DLLs | Copiadas ao lado do `.exe` por `make dist` | A pasta `dist/` ocupa ~47 DLLs, ~110 MB com `assets/`. |
| Assets | `SDL_GetBasePath()` + `chdir` no `main` | ~12 linhas novas; `assets/` precisa estar ao lado do executável. |
| Console | Release sem console (`-mwindows`), debug com console (`-mconsole`) | No release, as mensagens de `std::cout` ficam invisíveis. |
| Git | Branch nova + PR em `vieira-gabriel/Yawara_Game` | Exige um passo de merge. |
| Playtest | O usuário joga; Claude corrige os problemas relatados | Leva ~30–60 min do usuário. |

## Etapas

### 0. Preparação
- Criar a branch `fix/build-moderno` a partir de `master`.
- Copiar este plano para `docs/PLANO_BUILD.md` no repositório.

### 1. Limpeza do diretório de trabalho
- Apagar `bin/`, `lib/`, `build/` e `yawara.exe` da raiz.
- Apagar os diretórios em `include/` que não estão no git. Comando de conferência antes de apagar: `git ls-files include | cut -d/ -f2 | sort -u`. O resultado deve conter só `components engine resources states type`. Apagar apenas os diretórios **vazios** que não constam nessa lista (`find include -mindepth 1 -type d -empty`).
- Atualizar `.gitignore` com `build/`, `dist/`, `/yawara.exe` e `/yawara`. Corrigir `bin/` e `dep/` para `/bin/` e `/dep/`.

### 2. Correção do código (compilação)
- `include/resources/Text.h:51` → `unsigned int count;`.

### 3. Correção do Makefile (`Makefile`)
- `INC_PATH` → `$(wildcard include/*/) include/`. `SRC_PATH` → `$(wildcard src/*/) src/`. Isso remove o padrão `*/*/` que captura diretórios estranhos.
- Alvo `folders`: criar **só** `$(DEP_PATH)` e `$(BIN_PATH)` com `mkdir -p`. Remover `INC_PATH` e `SRC_PATH` da lista, porque esse alvo nunca deve criar diretórios de código.
- Remover `RMDIR = cmd /C rmdir` e `RM = cmd /C del` do bloco Windows. O `make` do MSYS2 usa `sh`, então `rm -rf`/`rm -f` servem nos dois sistemas.
- Bloco Windows: usar `SDL2_PREFIX ?= C:/msys64/mingw64`. Usar `pkg-config` dessa instalação quando ele existir (`$(SDL2_PREFIX)/bin/pkg-config` ou `PKG_CONFIG_PATH=$(SDL2_PREFIX)/lib/pkgconfig`), com os caminhos fixos atuais como alternativa. Manter a detecção do `g++` do mingw64.
- Na lista `SDL_PATHS` padrão do Windows, manter só `$(SDL2_PREFIX)`. Isso tira `/usr/local` e `/usr` do link no Windows e evita a mistura de runtimes. A variável `SDL2_PREFIX` continua permitindo apontar outra instalação.
- Linux: usar `pkg-config` como hoje. Corrigir o uso de `?=` em `SDL_INC_PATHS`/`LINK_PATH`, que já estão definidos vazios mais acima. Hoje o `?=` não tem efeito e a alternativa sem `pkg-config` nunca é aplicada.
- Remover `-D_USE_MATH_DEFINES` de `FLAGS` ou dos headers (ver etapa 5) para eliminar a redefinição.
- Novos alvos:
  - `run`: executa `./$(EXEC)` com `PATH="$(SDL2_PREFIX)/bin:$$PATH"` no Windows.
  - `dist`: cria `dist/yawara/` e copia o executável e `assets/` para lá. No Windows, também copia as DLLs listadas por `ldd $(EXEC) | grep -i mingw64 | awk '{print $$3}'` (~47 arquivos).
  - `clean` também remove `dist/`.
- Atualizar o texto do alvo `help` com os novos alvos.

### 4. Diretório de assets independente do diretório de trabalho (`src/Main.cpp`)
- No início do `main`, antes de `Game::GetInstance()`: chamar `char* base = SDL_GetBasePath();`. Se o retorno não for nulo, chamar `chdir(base)` (`_chdir` de `<direct.h>` no Windows, `chdir` de `<unistd.h>` no Linux, com `#ifdef _WIN32`) e depois `SDL_free(base)`.
- Também incluir `<ctime>`/`<cstdlib>`, porque o `main` usa `srand(time(NULL))` e hoje depende de includes transitivos.
- Consequência: no fluxo de desenvolvimento, o `.exe` fica na raiz do repositório, ao lado de `assets/`, como hoje. Em `dist/yawara/` ele também encontra `assets/`.

### 5. Warnings (a meta é zero warnings com `-Wall -Wextra -pedantic`)
- `_USE_MATH_DEFINES` redefinido: remover `#define _USE_MATH_DEFINES` de `include/states/StageState.h:15`, `Phase2State.h:15` e `Phase3State.h:15`, ou envolver cada um em `#ifndef`. O flag já vem do Makefile no Windows. No Linux, a glibc define `M_PI` sem esse flag.
- Narrowing `rand() % 2` → `float`: `src/components/Yawara.cpp:562` e `:580`. Usar `static_cast<float>(rand() % 2)`.
- `Rect` com cópia implícita depreciada (`include/type/Rect.h:23`, `void operator=(const Rect&)` declarado pelo usuário): ajustar para `Rect& operator=(const Rect&)` e declarar `Rect(const Rect&) = default;`. Ajustar a implementação em `src/type/Rect.cpp`. O warning aparece a partir de `src/components/Dark_Spirit.cpp:89`.
- Depois, compilar com `make clean && make` e confirmar que a saída não tem nenhuma linha `warning:`.

### 6. Referências mortas
- `include/resources/Tilemaps.h:5-11`: remover os `TM_MAP1_*` e `CL_MAP1`, que apontam para `assets/tilemap/cerrado_dark/mapa9/`, uma pasta inexistente. Antes, conferir com grep que nenhum `.cpp` usa esses nomes. A análise atual indica que o header só é incluído e esses nomes não são usados.
- `src/components/Dark_Spirit.cpp:41`: remover `SPRT_B_ATK_SOUND`, que aponta para `spirit/ataque.ogg`, um arquivo inexistente. Conferir que a constante não é usada. Se for usada, trocar pelo arquivo `assets/audio/sons/spirit/disparo.ogg`.
- Verificação: um script lista todos os literais `"assets/..."` do código e confirma que cada um existe. Os prefixos de tilemap são concatenados com o número do chunk e devem ser checados por prefixo.

### 7. CI no GitHub Actions (`.github/workflows/build.yml`)
- Job `linux` (`ubuntu-latest`): `apt-get install build-essential pkg-config libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev` → `make release`.
- Job `windows` (`windows-latest`): `msys2/setup-msys2` com `msystem: MINGW64` e os pacotes `mingw-w64-x86_64-gcc make mingw-w64-x86_64-pkgconf mingw-w64-x86_64-SDL2 mingw-w64-x86_64-SDL2_image mingw-w64-x86_64-SDL2_mixer mingw-w64-x86_64-SDL2_ttf` → `make release && make dist`. Publicar `dist/yawara` com `actions/upload-artifact`.
- Gatilhos: `push` e `pull_request`.

### 8. README (`README.md`)
- Reescrever a seção "Instalando" para Windows. Trocar o TDM-GCC pelo MSYS2: instalar o MSYS2, abrir o shell **MINGW64** e rodar `pacman -S` com os pacotes da etapa 7.
- Linux: corrigir `build-essencial` → `build-essential` e `libsdl2-ttf` → `libsdl2-ttf-dev`. Adicionar `pkg-config`.
- Documentar `make`, `make debug`, `make run`, `make dist` e `make clean`.
- Documentar o hack `F5` do Capelobo (`src/components/Capelobo.cpp:167`), que não consta na lista de hacks. Antes, conferir o que ele faz.

### 9. Playtest (o usuário joga; Claude corrige)
- Build: `make debug`, com console visível para ver os logs.
- Roteiro:
  1. Menu do título: Jogar, Controles, Sair, sons e música.
  2. Fase 1 (`StageState`): movimento, dash, mordida, Tapu, uivo nas runas, cristais e espíritos, cobra e Capelobo. Ver se a transição para a fase 2 ocorre (`StageState.cpp:383`).
  3. Fase 2 (`Phase2State`): ver se a transição para a fase 3 ocorre (`Phase2State.cpp:250`).
  4. Fase 3 (`Phase3State`): ver se os créditos aparecem (`Phase3State.cpp:175`).
  5. Pausa (Esc), game over (`F3`) e retorno ao título.
  6. Repetir com o `dist/yawara/yawara.exe` aberto por duplo clique no Explorer.
- Os hacks `F1` e `F2` aceleram o teste.
- O usuário relata cada crash ou comportamento errado com a saída do console. Claude corrige cada problema num commit separado.

### 10. Entrega
- Commits pequenos por etapa: limpeza/gitignore, `uint`, Makefile, base path, warnings, referências mortas, CI, README.
- Fazer push da branch para `origin` (`vieira-gabriel/Yawara_Game`) e abrir um PR para `master` no mesmo fork.
- Conferir o CI verde nos dois jobs antes do merge.

## Verificação ponta a ponta

1. No shell MSYS2 MINGW64, rodar `make clean && make`. O build não pode ter erros, e `grep -c warning:` na saída deve dar 0.
2. `make run`: o jogo abre na tela de título com música.
3. Num PowerShell comum, com o PATH apontando só para o ucrt64, rodar `make dist` e abrir `dist\yawara\yawara.exe` com duplo clique. O jogo deve abrir, o que prova que não depende do PATH nem do diretório de trabalho.
4. Os jobs `linux` e `windows` do GitHub Actions devem passar no PR.
5. O playtest da etapa 9 deve terminar nos créditos sem crash.

## Desvios registrados durante a execução

- **Etapa 3:** no Windows, o Makefile usa caminhos fixos de `SDL2_PREFIX` (`include`/`lib`) e não usa `pkg-config`. Esses caminhos já funcionavam, e o `pkg-config` do mingw64 não é necessário para o build. O alvo `make` copia para a raiz as DLLs listadas por `ldd` (alvo `dlls`), e `make run` executa o `.exe` da raiz sem alterar o PATH.
- **Etapa 4:** no Windows, o `chdir` usa `SetCurrentDirectoryW` com conversão UTF-8 → UTF-16. O motivo é que `_chdir` falha em caminhos com acento, como `Programação`.
- **Etapa 5:** os locais dos warnings estavam trocados no plano. O narrowing está em `src/components/Dark_Spirit.cpp:89`, e a cópia depreciada de `Rect` aparece em `src/components/Yawara.cpp:562/580`. O `operator=` de `Rect` foi removido, porque o operador implícito faz a mesma cópia.
- **Etapa 5 (novo):** o build com `-O3` acusou `tmp` possivelmente não inicializado em `src/resources/Text.cpp`. A correção inicializa `tmp` com `nullptr` e retorna com mensagem de erro se o TTF falhar, em vez de travar.
