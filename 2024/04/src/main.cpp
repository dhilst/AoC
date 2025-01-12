#include <algorithm>
#include <cassert>
#include <cmath>
#include <filesystem>
#include <functional>
#include <iostream>
#include <fstream>
#include <iterator>
#include <vector>
#include <expected>


using namespace std;

// Parsed input type
using input = vector<vector<char>>;

// Parse the input string into nested vector
input readinput(string path) {
    ifstream file(path);
    if (!file.is_open()) {
        throw filesystem::filesystem_error(
            "File not found",
            make_error_code(errc::no_such_file_or_directory)
        );
    }

    string line;
    vector<vector<char>> lines;
    while (getline(file, line)) {
        vector<char> linevec(line.begin(), line.end());
        lines.push_back(linevec);
    }
    return lines;
}

// Methods for collecting rows, columns and diagonals into vectors
struct input_wrapper : input {
    void rows(std::function<void(vector<char>)> func)
    {
        for (auto row : *this) {
            func(row);
        }
    }

    void columns(function<void(vector<char>)> func)
    {
        assert(!this->empty() && "Container is empty");
        auto column_max = (*this)[0].size();
        for (size_t c = 0; c < column_max; c++) {
            vector<char> column;
            for (auto lines : *this) {
                if (c < lines.size()) {
                    column.push_back(lines[c]);
                }
            }
            func(column);
        }
    }

    void diagonals(function<void(vector<char>)> func)
    {
        const int rows = size();
        assert(size() > 0);
        const int columns = (*this)[0].size();
        assert(rows >= columns);

        for (int d = 0 - (columns - 1); d <= (columns - 1); d++) {
            vector<char> diagonals;
            for (int x = 0, y = 0; x < rows; x++, y++) {
                auto xd = x + d;
                if (0 <= xd && xd < rows && y < columns) {
                    assert(size() > xd && (*this)[xd].size() > y);
                    diagonals.push_back((*this)[xd][y]);
                }
            }   
            func(diagonals);
        }
    }

    void diagonals2(function<void(vector<char>)> func)
    {
        const int rows = size();
        assert(size() > 0);
        const int columns = (*this)[0].size();
        assert(rows >= columns);

        for (int d = 0 - (columns - 1); d <= (columns - 1); d++) {
            vector<char> diagonals;
            for (int x = 0, y = columns - 1; x < rows; x++, y--) {
                auto xd = x + d;
                if (0 <= xd && xd < rows && y < columns) {
                    assert(size() > xd && (*this)[xd].size() > y);
                    diagonals.push_back((*this)[xd][y]);
                }
                if (y == 0) {
                    y = columns - 1;
                }
            }
            func(diagonals);
        }
    }
};

struct vecwrapper : vector<char> {
    // count number of xmas and samx in a vector
    unsigned count_xmas() {
        string temp;
        copy(begin(), end(), back_inserter(temp));

        int count = 0;
        for (size_t offset = 0; offset < temp.size(); offset++) {
            string_view temp_view = string_view{temp}.substr(offset);
            if (temp_view.starts_with("XMAS"))
                count++;
            if (temp_view.starts_with("SAMX"))
                count++;
        }

        return count;
    }
};

int main(int argc, char* argv[]) {
    input_wrapper inp = input_wrapper{readinput(argv[1])};
    int output = 0;
    auto accumulate = [&output](vector<char> vec) {
        output += vecwrapper{vec}.count_xmas();
    };

    // collect the vector in multiple directions and count
    // the XMAS and SAMX occurrences
    inp.rows(accumulate);
    inp.columns(accumulate);
    inp.diagonals(accumulate);
    inp.diagonals2(accumulate);

    cout << "Output: " << output << endl;
    return 0; 
}
