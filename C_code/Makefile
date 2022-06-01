all: GOL 

GOL: GOL.cpp OverlayControl.c OverlayControl.h utils.hpp utils.cpp
	g++ -O3 -Wall GOL.cpp OverlayControl.c  utils.cpp -o GOL -lm -lcma -lpthread -lncurses

GOL_no_display: GOL_no_display.cpp OverlayControl.c OverlayControl.h utils.hpp utils.cpp
	g++ -O3 -Wall GOL_no_display.cpp OverlayControl.c  utils.cpp -o GOL_no_display -lm -lcma -lpthread -lncurses

clean:
	rm -f GOL GOL_no_display

