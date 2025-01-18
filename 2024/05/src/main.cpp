#include <cassert>
#include <cmath>
#include <filesystem>
#include <iostream>
#include <ranges>
#include <stdexcept>
#include <string>
#include <vector>
#include <expected>
#include <fstream>


using namespace std;

using rule = pair<int, int>;
using update = vector<int>;

// Parsed input type
struct input {
    vector<rule> rules;
    vector<update> updates;
};

void print_rule(const rule& rule) {
    cout << "Rule " << rule.first << "," << rule.second << endl;
}

void print_update(const update& update) {
    cout << "Update ";
    for (auto up : update) {
        cout << up << ", ";
    }
    cout << endl;
}

void print_input(const input& input) {
    for (auto rule : input.rules) {
        print_rule(rule);
    }

    for (auto update : input.updates) {
        print_update(update);
    }
}

const char* expect_string_constant(const string& input, string constant)
{
    string_view input_view{input};
    auto subs = input_view.substr(0, constant.size());
    if (subs != constant) {
        throw std::invalid_argument(format("Expected {},  {}", constant, input_view));
    }

    return input.data() + constant.size();
}

const char* read_number(const string& input, int& number)
{
    auto result = std::from_chars(input.data(), input.data() + input.size(), number);
    
    if (result.ec != std::errc()) {
        throw std::invalid_argument("Failed to parse the number.");
    } 

    return result.ptr;
}

pair<int, int> read_rule(const string& line) {
    auto input = line;
    pair<int, int> output{};
    input = read_number(input, output.first);
    input = expect_string_constant(input, "|");
    input = read_number(input, output.second);
    return output;
}

vector<int> read_update(string_view input) {
    size_t start = 0;
    size_t end = input.find(',');
    vector<int> numbers;

    while (end != string_view::npos) {
        numbers.push_back(stoi(string(input.substr(start, end - start))));
        start = end + 1; // Move past the comma
        end = input.find(',', start);
    }

    // Don't forget the last number after the final comma
    numbers.push_back(stoi(string(input.substr(start))));
    return numbers;
}

input read_input(string path) {
    ifstream file(path);
    if (!file.is_open()) {
        throw filesystem::filesystem_error(
            "File not found",
            make_error_code(errc::no_such_file_or_directory)
        );
    }

    enum parser_state { READ_RULES, READ_UPDATES } state = READ_RULES;
    struct input input;
    string line;
    while (getline(file, line)) {
        switch (state) {
            case READ_RULES:
                if (line == "") {
                    state = READ_UPDATES;
                    continue;
                }
                input.rules.push_back(read_rule(line));
                break;
            case READ_UPDATES:
                input.updates.push_back(read_update(line));
                break;
            default:
                throw runtime_error("Fudeu");

        }
    }

    return input;
}


template<typename T>
constexpr bool in(T value, vector<T> vec) {
    return find(vec.begin(), vec.end(), value)  != vec.end();
}

bool valid(const span<const int>& pages_before,
           const int page,
           const span<const int>& pages_after,
           const vector<rule>& rules) {
    // page should be printed before [print_before]
    const vector<int> print_before = rules
        | ranges::views::filter([page](const rule rule) {
            return rule.second == page;
        })
        | ranges::views::transform([](const rule rule) {
            return rule.first;
        })
        | ranges::to<vector>();

    // page should be printed after [print_after]
    const vector<int> print_after = rules
        | ranges::views::filter([page](const rule rule) {
            return rule.first == page;
        })
        | ranges::views::transform([](const rule rule) {
            return rule.second;
        })
        | ranges::to<vector>();

    for (auto p : pages_before) {
        if (in(p, print_after))
            return false;
    }

    for (auto p : pages_after) {
        if (in(p, print_before))
            return false;
    }

    return true;
}

bool valid(const vector<int>& update,
           const vector<rule>& rules) {
    for (size_t i = 0; i < update.size(); ++i) {
        assert(update.size() > i);
        const auto upd = update[i];
        const span<const int> before(update.begin(), i + 1);
        const span<const int> after(update.begin() + i, update.size() - i);
        if (!valid(before, upd, after, rules))
            return false;
    }
    return true;
}

int middle(const update& update) {
    auto siz = update.size();
    assert(siz % 2 != 0);
    auto idx = (siz / 2);
    assert(siz > idx);
    auto middle = update[idx]; 
    return middle;
}

int main(int argc, char* argv[]) {
    input input = read_input(argv[1]);
    print_input(input);

    int output = 0;
    for (auto update : input.updates) {
        if (valid(update, input.rules)) {
            output += middle(update);
        }
    }

    cout << "Ouptut: " << output << endl;

    return 0; 
}
