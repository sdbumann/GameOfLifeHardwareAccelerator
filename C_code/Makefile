all: game 

game: game.cpp OverlayControl.c OverlayControl.h graphics.cpp graphics.hpp types.hpp utils.hpp utils.cpp
	g++ -O3 -Wall game.cpp OverlayControl.c graphics.cpp utils.cpp -o game -lm -lcma -lpthread -lncurses

clean:
	rm -f game

