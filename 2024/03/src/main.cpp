#include <cassert>
#include <charconv>
#include <cmath>
#include <iostream>
#include <fstream>
#include <vector>
#include <expected>
#include <optional>


using namespace std;

enum class ParserState {
    MUL,
    N1,
    COMMA,
    N2,
    RPAR,
};

std::optional<const int> parse_num(const string_view lineview) noexcept {
    int num;
    if (from_chars(lineview.data(), lineview.data() + 10, num).ec == errc()) {
        return num;
    }
    return nullopt;
}

const unsigned number_digits(const unsigned i) noexcept {
    return i > 0 ? log10(i) + 1 : 1;
}

class Parser {
private:
    ifstream& input;
    ParserState parser_state;
    string line;
public:
    Parser(ifstream& input) : parser_state(ParserState::MUL), input(input)
    {
    }

    // parse one line at time, returns nullopt when there are
    // no more lines to return. For each line, return a vector
    // with the pairs representing the mul(a,b) expressions in
    // that line.
    optional<vector<pair<int, int>>> parse_line() {
        if (!getline(input, line)) {
            return nullopt;
        }
        auto lineview = string_view(line);
        vector<pair<int,int>> muls;
        pair<int, int> p;
        vector<pair<int, int>> pairs;
        while (lineview.size() > 0) {
            switch (parser_state) {
                case ParserState::MUL:
                    {
                        auto result = lineview.starts_with("mul(");
                        if (result) {
                            lineview = lineview.substr(4);
                            parser_state = ParserState::N1;
                            continue;
                        } else {
                            lineview = lineview.substr(1);
                            continue;
                        }
                    }
                    break;
                case ParserState::N1:
                    { 
                        auto result = parse_num(lineview);
                        if (result) {
                            p.first = result.value();
                            lineview = lineview.substr(number_digits(result.value()));
                            parser_state = ParserState::COMMA;
                        } else {
                            parser_state = ParserState::MUL;
                            continue;
                        }
                    }
                    break;
                case ParserState::COMMA:
                    if (lineview.starts_with(",")) {
                        lineview = lineview.substr(1);
                        parser_state = ParserState::N2;
                    } else {
                        parser_state = ParserState::MUL;
                    }
                case ParserState::N2:
                    { 
                        auto result = parse_num(lineview);
                        if (result) {
                            p.first = result.value();
                            lineview = lineview.substr(number_digits(result.value()));
                            parser_state = ParserState::RPAR;
                        } else {
                            parser_state = ParserState::MUL;
                            continue;
                        }
                    }
                    break;
                case ParserState::RPAR:
                    if (lineview.starts_with(")")) {
                        // succesfull reading
                        pairs.emplace_back(p.first, p.second);

                        lineview = lineview.substr(1);
                        parser_state = ParserState::MUL;
                    } else {
                        parser_state = ParserState::MUL;
                    }
                    break;

            }
        }

        return pairs;
    }
};


int compute_output(vector<vector<pair<int, int>>> input)
{
    int output = 0;
    for (auto lines : input) {
        for (auto pair : lines) {
            output += pair.first + pair.second;
        }
    }
    return output;
}

// read the input
// parse the input
// ???
// print the output
int main(int argc, char* argv[]) {
    ifstream file(argv[1]);
    if (!file.is_open()) {
        cerr << "Error: Could not open the file!" << endl;
        return 1;
    }

    vector<vector<pair<int, int>>> parsed_result;
    Parser parser(file);
    while (auto parsed = parser.parse_line()) {
        parsed_result.push_back(parsed.value());
    }

    auto output = compute_output(parsed_result);

    // print the output
    cout << "Solution: " << output << endl;
    return 0; 
}
