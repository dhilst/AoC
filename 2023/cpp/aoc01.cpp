#include <iostream>
#include <ranges>

using namespace std;

int main(int arvc, char *argv[]) {
  using namespace std::views;
  using namespace std::ranges;

  auto solution = 0;
  constexpr auto digits = [](char ch){ return isdigit(ch); };
  constexpr auto first = []() { return take(1); };
  constexpr auto last = [](auto it){ return drop(it.size() - 1); };
  string num;
  num.reserve(2);

  for (string line; getline(cin, line);) {
    num.clear();
    auto ds = line | filter(digits) | to<string>();
    num += ds | first() | to<string>();
    num += ds | last(ds) | to<string>();
    if (!num.empty()) {
      solution += stoi(num);
    }
    cout << endl << "digits: " << num;
  }

  cout << endl << "Solution: " << solution << endl;
  return 0;
}
