#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <iostream>
#include <optional>
#include <ostream>
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

template <Streamable T>
std::ostream& operator<<(std::ostream& os, const std::vector<T>& vec)
{
    for (const auto& i : vec) {
        os << i;
    }
    return os;
 }

template <Streamable A, Streamable B>
std::ostream& operator<<(std::ostream& os, const std::pair<A, B>& pair)
{
    auto [a, b] = pair;
    os << "(" << a << ", " << b << ")";
    return os;
 }

using coordT = int;
using coord = std::pair<coordT, coordT>;
coord operator-(coord a1, coord a2)
{
    auto [x1, y1] = a1;
    auto [x2, y2] = a2;
    return std::make_pair(x1 - x2, y1 - y2);
}

coord operator+(coord a1, coord a2)
{
    auto [x1, y1] = a1;
    auto [x2, y2] = a2;
    return std::make_pair(x1 + x2, y1 + y2);
}

coord operator*(coord c, coordT n)
{
    return std::make_pair(c.first * n, c.second * n);
}

std::pair<coord, coord> findAntinodes(coord a1, coord a2)
{
    auto [x1, y1] = a1;
    auto [x2, y2] = a2;
    auto d = a2 - a1;
    auto ant1 = a1 - d;
    auto ant2 = a2 + d;
    return std::make_pair(ant1, ant2);
}


TEST(BasicTest, FindAntinodes) {
    auto [ant1, ant2] = findAntinodes(std::make_pair(3, 4), std::make_pair(5, 5));
    ASSERT_EQ(ant1, std::make_pair(1, 3));
    ASSERT_EQ(ant2, std::make_pair(7, 6));
}

std::vector<coord> findAntinodesWithResonantHarmonics(coord a1, coord a2, auto boundCheck)
{
    std::vector<coord> output;
    auto [x1, y1] = a1;
    auto [x2, y2] = a2;
    auto d = a2 - a1;

    for (auto n = 0;; n++) {
        coord an1n = a1 - (d * n);
        if (boundCheck(an1n)) {
            output.push_back(an1n);
        } else {
            break;
        }
    }

    for (auto n = 0;; n++) {
        coord an2n = a2 + (d * n);
        if (boundCheck(an2n)) {
            output.push_back(an2n);
        } else {
            break;
        }
    }

    return output;
};

// Returns x if cb(x) == true
// assertion fails otherwise
inline constexpr auto assertId(auto&& x, const auto& cb)
{
    auto v = cb(x);
    assert(v);
    return std::forward<decltype(x)>(x);
}


struct input {
    std::size_t rowSize;
    std::vector<char> data;
    std::size_t columnSize = assertId(data.size() / rowSize,
                                      [&](auto _) { return data.size() % rowSize == 0; });

    char get(std::size_t i) const
    {
        assert(i < data.size());
        return data[i];
    }

    char get(coord c) const
    {
        return get(idx(c.first, c.second));
    }

    static constexpr bool valid(coord c, auto columnSize, auto rowSize)
    {
        auto [x, y] = c;
        return x >= 0 && x < columnSize && y >= 0 && y < rowSize;
    }

    static constexpr auto idx(std::size_t x, std::size_t y, std::size_t rowSize)
    {
        return y + x * rowSize;
    }

    static constexpr auto idx(coord c, auto columnSize, auto rowSize)
    {
        assert(valid(c, columnSize, rowSize));
        auto [x, y] = c;
        return idx(static_cast<std::size_t>(x), static_cast<std::size_t>(y), rowSize);
    }

    static auto invidx(auto i, auto rowSize)
    {
        assert(rowSize > 0);
        auto x = i / rowSize;
        auto y = i % rowSize;
        return std::make_pair(x, y);
    }

    bool valid(coord c) const
    {
        return valid(c, columnSize, rowSize);
    }

    std::size_t idx(auto x, auto y) const { return idx(x, y, rowSize); }
    std::size_t idx(coord c) const { return idx(c, rowSize); }
    auto invidx(int i) const { return invidx(i, rowSize); }

    char nth(auto x, auto y) const
    {
        std::size_t i = idx(x, y);
        assert(i < data.size());
        return data[i];
    }

    char nth(coord c) const
    {
        assert(valid(c));
        auto [x, y] = c;
        return nth(x, y);
    }
 
    std::optional<char> nthopt(std::size_t x, std::size_t y) const
    {
        auto i = idx(x, y);
        if (i < data.size()) {
            return data[i];
        }
        return std::nullopt;
    }

    auto nthopt(coord c) const
    {
        auto [x, y] = c;
        return nthopt(x, y);
    }

    static auto makeVisit(std::size_t a, std::size_t b)
    {
        assert(a != b);
        return a < b ? std::make_pair(a, b) : std::make_pair(b, a);
    }

    void iterate(std::function<void(coord a1, coord a2)> cb)
    {
        // This is not a coordinte, it is a pair of indexes of data member
        std::set<std::pair<std::size_t, std::size_t>> visited;

        for (auto i = 0; i < data.size(); ++i)
        {
            for (auto j = 0; j < data.size(); ++j)
            {
                if (i == j)
                    continue;

                // The possibly nodes positions
                auto node1 = get(i);
                auto node2 = get(j);

                if (node1 == '.' || node2 == '.' || node1 == '#' || node2 == '#') continue;
                if (node1 != node2) continue;

                assert(node1 == node2 && node1 != '.');

                auto node1p = invidx(i);
                auto node2p = invidx(j);
                auto visitPair = makeVisit(i, j);
                // Avoid calling the callback twicewith swapped
                // arguments e.g calling cb(B, A) after calling cb(A, B)
                if (visited.contains(visitPair)) continue;
                visited.insert(visitPair);
                cb(node1p, node2p);
            }
        }
    }

};

TEST(BasicTest, InputIndex) {
    const std::size_t rowSize = 10;
    const std::size_t columnSize = 10;
    auto i = 13;
    coord c = input::invidx(13, rowSize);
    constexpr auto idx = [rowSize](coord c) { return input::idx(c, columnSize, rowSize); };
    constexpr auto invidx = [rowSize](auto i){ return input::invidx(i, rowSize); };
    ASSERT_EQ(idx(c), i);
    ASSERT_EQ(invidx(i), c);
    ASSERT_EQ(invidx(idx(c)), c);
    ASSERT_EQ(idx(invidx(i)), i);
}

auto readinput(std::istream& fil)
{
    std::string line;
    std::vector<char> output;
    std::size_t rowSize = 0;
    while (std::getline(fil, line)) {
        // ensure all lines have the same length
        assert(rowSize == 0 || rowSize == line.size());
        rowSize = line.size();
        output.insert(output.end(), line.begin(), line.end());
    }
    return input{rowSize, std::move(output)};
}

TEST(BasicTest, Input) {
    std::istringstream data("123\n456");

    auto input = readinput(data);
    ASSERT_EQ(input.rowSize, 3);
    ASSERT_EQ(input.nth(0, 0), '1');
    ASSERT_EQ(input.nth(0, 1), '2');
    ASSERT_EQ(input.nth(1, 1), '5');
    ASSERT_DEATH(input.nth(0, 100), ".*");
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
    assert(input.rowSize > 0);

    std::vector<std::size_t> antinodesIndexes;
    std::set<std::size_t> antinodesHarmonicsIndexes;

    input.iterate(
        [&](coord antenna1c, coord antenna2c)
        {
            auto [antinode1c, antinode2c] = findAntinodes(antenna1c, antenna2c);
            auto antinodesWithHarmonics = findAntinodesWithResonantHarmonics(antenna1c, antenna2c, [&](auto& c) { return input.valid(c); });
            // I need to check if there is no antena over it
            std::cout << 
                "Iterating over antenas: " << input.get(antenna1c) << " " << antenna1c << " " << antenna2c << std::endl;
            if (input.valid(antinode1c)) {
                auto antinode1i = input.idx(antinode1c);
                std::cout << 
                     "Found valid antinode 1 " << antinode1c << std::endl;
                antinodesIndexes.push_back(antinode1i);
                //if (input.get(antinode1i) == '.')
                //    input.data[antinode1i] = '#';
            }
            if (input.valid(antinode2c)) {
                auto antinode2i = input.idx(antinode2c);
                std::cout << 
                    "Found valid antinode 2 " << antinode2c << std::endl;
                antinodesIndexes.push_back(antinode2i);
                //if (input.get(antinode2i) == '.')
                //    input.data[antinode2i] = '#';
            }

            for (auto& antinode : antinodesWithHarmonics) {
                auto index = input.idx(antinode);
                antinodesHarmonicsIndexes.insert(index);
                if (input.get(index) == '.') {
                    input.data[index] = '#';
                }
            }
        });

    std::cout << "Input marked" << std::endl;
    for (auto i = 0; i < input.rowSize; ++i) {
        for (auto j = 0; j < input.data.size() / input.rowSize; ++j) {
            std::cout << input.nth(i, j);
        }
        std::cout << std::endl;
    }

    // The missing antinode
    // plus an antinode overlapping the topmost A-frequency antenna:
    
    std::set<std::size_t> antinodesSet;
    antinodesSet.insert(antinodesIndexes.begin(), antinodesIndexes.end());

    std::cout << "Output 1: " << antinodesSet.size() << std::endl;
    std::cout << "Output 2: " << antinodesHarmonicsIndexes.size() << std::endl;
    return 0;
}
