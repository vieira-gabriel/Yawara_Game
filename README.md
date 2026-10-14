# Yawara

Jogo desenvolvido para o trabalho final de Introdução ao Desenvolvimento de Jogos da Universidade de Brasília no primeiro semestre de 2019.

## Projeto

O repositório do projeto pode ser encontrado no [GitHub](https://github.com/Takashi-san/Yawara_Game/)

## Licensa

Todos os arquivos referentes ao projeto se encontram sobre licensa de Open Source, disponíveis para serem usados, modificados e compartilhados livremente citando os autores originais.

## Iniciando

Estas instruções vão ensinar a como compilar e rodar o jogo 'Yawara' desenvolvido para a disciplina de Introdução ao Desenvolvimento de Jogos

### Pré-requisitos

Para compilar o programa, os seguintes fazem-se necessários:
```
g++ com suporte a C++11
make
SDL2
SDL2_image
SDL2_mixer
SDL2_ttf
```

### Instalando

#### Linux (via terminal)

* Debian/Ubuntu:
    ```
    sudo apt-get install build-essential pkg-config libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
    ```

* Arch:
    ```
    sudo pacman -S base-devel sdl2 sdl2_image sdl2_mixer sdl2_ttf
    ```

#### Windows (MSYS2)

1. Instale o [MSYS2](https://www.msys2.org/) no caminho padrão `C:\msys64`.
2. Abra o terminal **MSYS2 MINGW64** e instale o compilador e as bibliotecas:
    ```
    pacman -S make mingw-w64-x86_64-gcc mingw-w64-x86_64-SDL2 mingw-w64-x86_64-SDL2_image mingw-w64-x86_64-SDL2_mixer mingw-w64-x86_64-SDL2_ttf
    ```
3. Os comandos de compilação devem ser executados num shell `sh`, como o terminal MSYS2 MINGW64 ou o Git Bash.

O Makefile usa o `g++` e as bibliotecas de `C:/msys64/mingw64`. Para usar outra instalação, passe o caminho com `make SDL2_PREFIX=<caminho>`. Não misture ambientes do MSYS2 (por exemplo, `ucrt64` e `mingw64`), porque os runtimes são incompatíveis.

## Compilando e jogando

Na pasta do projeto, compile com o comando
```
make
```

Os alvos disponíveis são:

| Comando | Resultado |
|---|---|
| `make` ou `make release` | Compila a versão otimizada. No Windows, o jogo abre sem janela de console. |
| `make debug` | Compila a versão de depuração. No Windows, o jogo abre com janela de console para exibir mensagens de erro. |
| `make run` | Compila e executa o jogo. |
| `make dist` | Gera a pasta `dist/yawara` com o executável, as DLLs (no Windows) e a pasta `assets`, pronta para ser copiada para outro computador. |
| `make clean` | Apaga os arquivos gerados. Execute antes de trocar entre `release` e `debug`. |

No Windows, o `make` copia para a pasta do projeto as DLLs da SDL2 de que o executável precisa. Assim, `yawara.exe` abre com duplo clique, sem alterar o PATH.

O jogo procura a pasta `assets` ao lado do executável. Por isso, ele pode ser aberto a partir de qualquer diretório:
```
./yawara
```

## Feito com
* [SDL2](https://wiki.libsdl.org/)
* [SDL_image](http://www.libsdl.org/projects/SDL_image/)
* [SDL_mixer](http://www.libsdl.org/projects/SDL_mixer/)
* [SDL_ttf](http://www.libsdl.org/projects/SDL_ttf/)

## Desenvolvedores

**Programadores:**
- Bruno Takashi
    - Responsável por Yawara, câmera, carregamento do cenário, transição de cena, estágios do jogo, colisão do mapa, cobra, cursor, eventos de música, hitbox.
- Gabriel Vieira
    - Responsável por Capelobo, inimigos, cobra, classe Floor (prévia do mapa de colisão), danos por colisão, eságios de pausa e fim do jogo.
- Leonardo Alves
    - Responsável por Tapu, adaptação de funções de easing, estágios de título, pausa e fim de jogo, interações (runas, cristais e espíritos corrompidos), hacks, projéteis (Bullets), eventos.

**Designers:**
- Adriel Ramon
- Bruna Dias
- Luciana Liu Lu
- Raimundo Marques

**Músicos:**
- Daniel Araujo
- Rafael Cardim
- Rafael Gama

## O Jogo

### História
Os irmãos Jaci, deusa da lua, e Guaraci, deus do sol, eram venerados e adorados por todos enquanto Tupã, deus da tempestade, era ignorado. Tupã sentia um rancor por ser menosprezado pelos deuses e em um ataque de fúria, acerta Guaraci por trás e o mata. Assim, Tupã reivindica seu lugar nos céus e joga poderes em animais que se tornam seus guardiões.

Jaci, fica em choque e é levada por Tupã pra ser selada. Enquanto isso Guaraci está deitado no chão sangrando. As gotas de sangue caem sobre um lobo guará jovem, que acaba por se tornar Yawara, a reencarnação de Guaraci. Jaci, por sua vez, chora e a partir de suas lágrimas surge o Tapa, espírito guardião de Guaraci.

O objetivo de Yawara é derrotar Tupã e seus guardiões pra recuperar a força de Guaraci para assim voltar aos céus junto de sua querida irmã Jaci.

### Gênero do jogo

Yawara é um jogo com foco em boss-fighting, entretando contém elementos de exploração, para realmente contar a história do jogo, e de observação, trazendo o território brasileiro como cenário, dando um ar aventuresco ao jogo.

### Controles
Controles de Yawara (lobo-guará):
* <kbd>W</kbd>, <kbd>A</kbd>, <kbd>S</kbd>, <kbd>D</kbd>: movimenta para cima, esquerda, baixo e direita. Combinaçoes de teclas (<kbd>W</kbd> + <kbd>A</kbd> ou <kbd>S</kbd> + <kbd>D</kbd> por exemplo) movimentam em direções intermediárias;
* <kbd>Espaço</kbd>: "dash", movimento de velocidade de Yawara que não aplica dano a inimigos;
* <kbd>E</kbd>: uivo, interage com o ambiente onde possível (runas, espíritos corrompidos e cristais);
* Clique direito: mordida, ataque de proximidade co dano mais elevado.

Controles de Tapu (espírito companheiro):
* Mouse: movimenta dentro de uma área ao redor de Yawara;
* Clique esquerdo: ataque de energia, ataque a distância com dano reduzido.

Câmera:
* Foco automático entre o cursor do mouse e Yawara;

### Hacks

* <kbd>F1</kbd>: eleva vida (HP), defesa e dano de Yawara;
* <kbd>F2</kbd>: retorna stats (vida, defesa e dano) aos originais;
* <kbd>F3</kbd>: suicídio
* <kbd>F5</kbd>: zera a vida do Capelobo (chefe da primeira fase)

### Jogando

Ao jogar Yawara, seu objetivo é derrotar as forças do mal que corrompem a vida brasileira. Durante o jogo, deve-se vencer Capelobo para restaurar o Cerrado brasileiro e Boiuna para restaurar a Mata Atlântica, salvando assim o território brasileiro.
Caso as forças do mal derrotem Yawara, retirando sua força vital, o Brasil fica corrompido e o mal vence.