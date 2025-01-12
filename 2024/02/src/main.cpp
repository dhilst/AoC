#include <algorithm>
#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>


using namespace std;
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

    vector<vector<int>> numberLines;

    // parse the input
    string line;
    while (getline(file, line)) {
        vector<int> numbers;

        istringstream iss(line);
        int num;
        while (iss >> num) {
            numbers.push_back(num);
        }
        numberLines.push_back(numbers);
    }

    int output = 0;
    for (const auto& innerVec : numberLines) {
        // 1. The levels are either all increasing or all decreasing.
        if (!is_sorted(innerVec.begin(), innerVec.end()) && !is_sorted(innerVec.rbegin(), innerVec.rend()))
            continue;

        int bad = 0;
        for (size_t i = 0; i + 1 < innerVec.size(); i++) {
            // 2. Any two adjacent levels differ by at least one and at most three.
            //           1 <= |a - b| <= 3
            const auto d = abs(innerVec[i] - innerVec[i+1]);
            if (!(1 <= d && d <= 3)) {
                bad = 1;
                break;
            }
        }
        if (!bad)
            output++;
    }

    // print the output
    cout << output << endl;
    return 0; 
}
