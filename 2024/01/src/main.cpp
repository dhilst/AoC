#include <algorithm>
#include <iostream>
#include <fstream>
#include <vector>


// read the input
// split into left and right lists
// sort both
// pair up again
// subtract each pair ( figure out how far apart the two numbers)
// sum the list
int main(int argc, char* argv[]) {
    std::ifstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open the file!" << std::endl;
        return 1;
    }

    int left, right;
    std::vector<int> leftNumbers, rightNumbers;

    while (file >> left >> right) {
        leftNumbers.push_back(left);
        rightNumbers.push_back(right); // Add pair to the vector
        std::cout << "Number 1: " << left << ", Number 2: " << right << std::endl;
    }

    std::sort(leftNumbers.begin(), leftNumbers.end());
    std::sort(rightNumbers.begin(), rightNumbers.end());
    
       // Iterate using index
    int output = 0;
    for (size_t i = 0; i < leftNumbers.size(); ++i) {
        output += std::abs(leftNumbers[i] - rightNumbers[i]);
    }
    
    std::cout << output << std::endl;
    return 0;
}
