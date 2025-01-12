.PHONY: all clean

ALL = $(subst .cpp,,$(shell echo *.cpp))

%: %.cpp
	$(CPP) -Wall -std=c++23 -o $@ $<

all: $(ALL)

clean:
	rm -f $(ALL)
