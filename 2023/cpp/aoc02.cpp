#include <cstdio>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <utility>

using namespace std;


/// Reads a literal from a istream with >> operator
class lit {
  const string s;

public:
  lit(string s) : s(s) {}

  friend istream &operator>>(istream &in, const lit &l) {
    string token;
    token.reserve(l.s.size());
    in >> token;
    if (in.good() && token != l.s) {
      in.setstate(ios_base::failbit);
    }

    return in;
  }
};


enum class Color {
  Green, Red, Blue,
};

istream& operator>>(istream &in, Color &c)
{
  string colorStr;
  colorStr.reserve(5);
  in >> colorStr;
  if (colorStr == "red") {
    *c = Color::Red;
  } else if (colorStr == "green") {
    c = Color::Green;
  } else if (colorStr == "blue") {
    c = Color::Blue;
  } else {
    in.setstate(ios_base::failbit);
  }

  return in;
};

ostream& operator<<(ostream &out, const Color &c)
{
  switch (c) {
    case Color::Red:
      out << "red";
      break;
    case Color::Green:
      out << "green";
      break;
    case Color::Blue:
      out << "blue";
      break;
    default:
      out.setstate(ios_base::failbit);
  }
  return out;
}

int main(int arvc, char *argv[]) {
  auto err = invalid_argument("Bad input");

  for (string line; getline(cin, line);) {
    istringstream tokens(line);
    int game{}, num{};
    Color color{};

    tokens >> lit("Game") >> game >> lit(":");
    if (tokens.fail()) {
      continue;
    }


    tokens >> num >> color;

    cout << "Game " << game << ", Color " << num << " " << color << endl;
  }

  return 0;
}
//
// Input
//
// Game 1: 10 red, 7 green, 3 blue; 5 blue, 3 red, 10 green; 4 blue, 14 green, 7
// red; 1 red, 11 green; 6 blue, 17 green, 15 red; 18 green, 7 red, 5 blue Game
// 2: 13 green, 10 red; 11 green, 1 blue, 7 red; 5 red, 12 green, 1 blue; 12
// green, 6 red; 8 green, 5 red; 12 green, 1 red
