#pragma once // Alows to initializate the header just once

#define INCLUDE_SDL
#include "SDL_include.h"
#include "Music.h"
#include "State.h"
#include "TileSet.h"
#include "Sprite.h"

#include <string>
#include <iostream>
#include <stdbool.h>
#include <memory>
#include <vector>
#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES
#endif
#include <math.h>

class Phase3State : public State
{
private:
	Music bgMusic;
	TileSet *tileset;

	Sprite* black;
	Sprite* white;

	bool ignore, flag;
public:
	Phase3State();
	~Phase3State();

	void LoadAssets();
	void Update(float dt);
	void Render();

	void Start();
	void Pause();
	void Resume();
};