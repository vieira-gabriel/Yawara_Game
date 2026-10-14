#include "Game.h"
#include "TitleState.h"

#include <cstdlib>
#include <ctime>
#ifdef _WIN32
	#include <windows.h>
#else
	#include <unistd.h>
#endif

// Muda o diretório de trabalho para a pasta do executável, onde fica assets/.
static void ChangeToBaseDir() {
	char* base = SDL_GetBasePath();
	if (base == nullptr) {
		return;
	}
#ifdef _WIN32
	// SDL_GetBasePath retorna UTF-8; o Windows exige UTF-16 para caminhos com acento.
	wchar_t wbase[MAX_PATH];
	if (MultiByteToWideChar(CP_UTF8, 0, base, -1, wbase, MAX_PATH) == 0 || !SetCurrentDirectoryW(wbase)) {
		std::cout << "Erro ao mudar para o diretório do executável: " << base << "\n";
	}
#else
	if (chdir(base) != 0) {
		std::cout << "Erro ao mudar para o diretório do executável: " << base << "\n";
	}
#endif
	SDL_free(base);
}

int main(int argc, char** argv) {
	ChangeToBaseDir();

	srand (time(NULL));
	Game& game = Game::GetInstance();
	TitleState* init = new TitleState();

	game.Push(init);
	game.Run();

	return 0;
}
