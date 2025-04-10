#include "gtest/gtest.h"
#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <iostream>
#include <optional>
#include <ostream>
#include <random>
#include <stdexcept>
#include <utility>
#include <vector>
#include <sstream>
#include <fstream>
#include <cassert>
#include <ranges>

#include <gtest/gtest.h>


template <typename T>
concept Streamable = requires(const T &s, std::ostream &os) { os << s; };

template <Streamable A, Streamable B>
std::ostream& operator<<(std::ostream& os, const std::pair<A, B>& p)
{
    os << "(" << p.first << ", " << p.second << ")";
    return os;
}


template <typename T>
std::ostream& operator<<(std::ostream& os, const std::vector<T>& vec)
{
    for (const auto& i : vec) {
        os << i << ",";
    }
    return os;
}

std::uint8_t toUint(char ch)
{
    assert('0' <= ch && ch <= '9');
    return ch - '0';
}

constexpr std::vector<char> ofString(const std::string& str)
{
    std::vector<char> output(str.begin(), str.end());
    return output;
}

constexpr std::string toString(const std::vector<char>& vec)
{
    std::ostringstream os;
    for (auto i : vec) {
        os << i;
    }

    return os.str();
}

constexpr int FREEBLOCK = -1;
using Block = std::pair<int, std::size_t>; // id | size
constexpr std::string toString(const std::vector<Block>& vec)
{
    std::ostringstream os;
    for (auto& [id, size] : vec) {
        auto sym = id == FREEBLOCK ? "." : std::format("{}", id);
        for (auto i = 0; i < size; ++i) {
            os << sym;
        }
    }
    return os.str();
};


// -1 are free blocks
// n >= 0 represent the ids
std::vector<int> diskMapToBlocks(const std::string& input)
{
    std::vector<int> output;
    for (auto i = 0; i < input.size(); ++i) {
        char ch = input[i];
        assert('0' <= ch && ch <= '9');
        bool isFree = i % 2 != 0;
        int sym = isFree ? FREEBLOCK : i/2;
        auto n = ch - '0';
        while (n-- > 0) {
            output.push_back(sym);
        }
    }
    return output;
}

std::vector<std::pair<int,std::size_t>> diskMapToFiles(const std::string& input)
{
    std::vector<std::pair<int, std::size_t>> output;
    for (auto i = 0; i < input.size(); ++i) {
        char ch = input[i];
        assert('0' <= ch && ch <= '9');
        bool isFree = i % 2 != 0;
        int sym = isFree ? FREEBLOCK : i/2;
        auto n = ch - '0';
        output.emplace_back(sym, n);
    }
    return output;
}

TEST(BasicTest, TestDiskMapToBlocks)
{
    auto vec = std::vector<int>{0, -1,-1, 1,1,1, -1,-1,-1,-1, 2,2,2,2,2};
    ASSERT_EQ(diskMapToBlocks("12345"), vec);
    auto vec2 = std::vector<int>{0,0,-1,-1,-1,1,1,1,-1,-1,-1,2,-1,-1,-1,3,3,3,-1,4,4,-1,5,5,5,5,-1,6,6,6,6,-1,7,7,7,-1,8,8,8,8,9,9};
    auto  out = diskMapToBlocks("2333133121414131402");
    ASSERT_EQ(out, vec2);
    ASSERT_EQ(toString(diskMapToFiles("12345")), "0..111....22222");
} 

auto unpackFreeSpace(const std::vector<int>& inputVec)
{
    constexpr auto findLastNonFree = [](auto& inputVec) {
        for (int tail = inputVec.size() - 1; tail > 0; --tail) {
            if (inputVec[tail] != FREEBLOCK) {
                return tail;
            }
        }
        return -1;
    };
    constexpr auto findNextFree = [](auto& inputVec) {
        for (int i = 0; i < inputVec.size(); ++i) {
            if (inputVec[i] == FREEBLOCK) {
                return i;
            }
        }
        return -1;
    };
    constexpr auto swap = [&](int a, int b, auto& inputVec) {
        auto tmp = inputVec[b];
        inputVec[b] = inputVec[a];
        inputVec[a] = tmp;
    };

    auto copy = std::vector(inputVec); // copy
    while (true) {
        auto lastUsed = findLastNonFree(copy);
        auto firstFree = findNextFree(copy);
        if (lastUsed != -1 && firstFree != -1 && lastUsed > firstFree) {
            swap(firstFree, lastUsed, copy);
        } else {
            break;
        }
    }

    return copy;
}

auto unpackFreeSpaceFile(const std::vector<std::pair<int, std::size_t>>& inputVec)
{
    constexpr auto findLastNonFree = [](const auto& inputVec, int startAt) {
        assert(startAt >= 0);
        assert(startAt < inputVec.size());
        for (int tail = startAt; tail >= 0; --tail) {
            if (inputVec[tail].first != FREEBLOCK) {
                return tail;
            }
        }
        return -1;
    };
    constexpr auto findNextFreeWithSize = [](const auto size, const auto& inputVec, const auto limit) {
        for (int i = 0; i < inputVec.size() && i < limit; ++i) {
            if (inputVec[i].first == FREEBLOCK && inputVec[i].second >= size) {
                return i;
            }
        }
        return -1;
    };

    constexpr auto split = [](const Block& block, const Block& freespace)
        -> std::pair<Block, Block> {
            assert(freespace.second >= block.second);
            auto remainingSize = freespace.second - block.second;
            auto leftBlock = std::make_pair(FREEBLOCK, remainingSize);
            auto rightBlock = std::make_pair(FREEBLOCK, block.second);
            return std::make_pair(leftBlock, rightBlock);
    };

    assert(inputVec.size() > 0);
    auto copy = std::vector(inputVec); // copy
    for (int tail = copy.size() - 1; tail >= 0; --tail) {
        auto lastBlock = copy[tail];
        if (lastBlock.first == FREEBLOCK) {
            continue;
        }
        assert(lastBlock.first != FREEBLOCK);
        // lastBlock is non free, lets try to move it
        auto head = findNextFreeWithSize(lastBlock.second, copy, tail);
        if (head == -1) { // not found
            continue;
        }
        auto freeBlock = copy[head];
        auto remaining = freeBlock.second - lastBlock.second;
        auto remainingFreeBlock = std::make_pair(FREEBLOCK, remaining);
        auto relocatedFreeBlock = std::make_pair(FREEBLOCK, lastBlock.second);
        copy[head] = copy[tail];
        copy[tail] = relocatedFreeBlock;
        if (remainingFreeBlock.second > 0) {
            copy.insert(copy.begin() + head + 1, remainingFreeBlock);
        }
    }

    return copy;
}

TEST(BasicTest, UnpackFreeSpace)
{
    //ASSERT_EQ(toString(diskMapToFiles("12345")), "0..111....22222");
    ASSERT_EQ(toString(diskMapToFiles("2333133121414131402")), "00...111...2...333.44.5555.6666.777.888899");
    ASSERT_EQ(toString(diskMapToFiles("12345")), "0..111....22222");
    ASSERT_EQ(toString(diskMapToFiles("333")), "000...111");
    ASSERT_EQ(toString(unpackFreeSpaceFile(diskMapToFiles("333"))), "000111...");
    ASSERT_EQ(toString(diskMapToFiles("332")), "000...11");
    ASSERT_EQ(toString(unpackFreeSpaceFile(diskMapToFiles("332"))), "00011...");
    ASSERT_EQ(toString(diskMapToFiles("33412")), "000...1111.22");
    ASSERT_EQ(toString(unpackFreeSpaceFile(diskMapToFiles("33412"))), "00022.1111...");
    ASSERT_EQ(toString(unpackFreeSpaceFile(diskMapToFiles("2333133121414131402"))), "00992111777.44.333....5555.6666.....8888..");
}

std::uint64_t checksum(const std::vector<int>& compactedStr)
{
    std::uint64_t output = 0;
    auto position = 0;
    for (auto ch : compactedStr) {
        if (ch != FREEBLOCK) {
            output += position * ch;
        }
        position++;
    }

    return output;
}

std::vector<int> fromBlockVec(const std::vector<Block>& vec)
{
    std::vector<int> output;
    for (auto [id, size] : vec) {
        for (auto i = 0; i < size; ++i) {
            output.push_back(id);
        }
    }
    return output;
}

TEST(BasicTest, Checksum)
{
    ASSERT_EQ(checksum(unpackFreeSpace(diskMapToBlocks(   "2333133121414131402"))), 1928);
    //ASSERT_EQ(checksum(unpackFreeSpaceFile(diskMapToFiles("2333133121414131402"))), 2858);
    ASSERT_EQ(checksum(fromBlockVec(unpackFreeSpaceFile(diskMapToFiles("2333133121414131402")))), 2858);
}

auto readinput(std::istream& fil)
{
    std::string line;
    std::vector<char> output;
    while (std::getline(fil, line)) {
        output.insert(output.end(), line.begin(), line.end());
    }
    return output | std::ranges::to<std::string>();
}

auto readinput(const std::filesystem::path& path)
{
    std::ifstream input(path);
    return readinput(input);
}

int main(int argc, char* argv[])
{
    const char* run_tests = std::getenv("RUN_GTEST");
    if (run_tests != nullptr && std::string(run_tests) != "") {
        ::testing::InitGoogleTest(&argc, argv);
        return RUN_ALL_TESTS();
    }

    auto input = readinput(argv[1]);
    auto blocks = diskMapToBlocks(input);
    auto blocksFiles = diskMapToFiles(input);
    auto unpacked = unpackFreeSpace(blocks);
    auto unpackedFiles = unpackFreeSpaceFile(blocksFiles);
    std::cout << "Output: " << checksum(unpacked) << std::endl;
    std::cout << "Output: " << checksum(fromBlockVec(unpackedFiles)) << std::endl;
    return 0;
}
