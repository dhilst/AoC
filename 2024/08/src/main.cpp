#include <algorithm>
#include <bitset>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <iostream>
#include <memory>
#include <numeric>
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

template <typename T = std::uint64_t>
T intFromStr(std::string_view str)
{
    T i{};
    auto [_, ec] = std::from_chars(str.data(), str.data() + str.size(), i);
    if (ec != std::errc{}) {
        throw std::invalid_argument("Invalid argument");
    }

    return i;
}

TEST(BasicTests, To)
{
    ASSERT_EQ(intFromStr("10"), 10);
    ASSERT_EQ(intFromStr("20"), 20);
    ASSERT_EQ(intFromStr("0"), 0);
}

bool isIn(auto value, auto& vec)
{
    return std::find(vec.begin(), vec.end(), value) != vec.end();
}

TEST(BasicTests, isIn)
{
    const auto v = std::vector{1,2,3};
    ASSERT_EQ(isIn(1, v), true);
    ASSERT_EQ(isIn(4, v), false);
}

auto collect()
{
    return std::ranges::to<std::vector>();
}


using coord = std::pair<std::size_t, std::size_t>;
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

std::pair<coord, coord> findAntinodes(coord a1, coord a2)
{
    auto [x1, y1] = a1;
    auto [x2, y2] = a2;
    auto d = std::make_pair(x2 - x1, y2 - y1);
    auto ant1 = a1 - d;
    auto ant2 = a2 + d;
    return std::make_pair(ant1, ant2);
}

TEST(BasicTest, FindAntinodes) {
    auto [ant1, ant2] = findAntinodes(std::make_pair(3, 4), std::make_pair(5, 5));
    ASSERT_EQ(ant1, std::make_pair(1, 3));
    ASSERT_EQ(ant2, std::make_pair(7, 6));
}

struct input {
    std::size_t rowSize;
    std::vector<char> data;

    char get(std::size_t i) const
    {
        assert(i < data.size());
        return data[i];
    }

    char get(coord c) const
    {
        return get(idx(c.first, c.second));
    }

    static constexpr auto idx(std::size_t x, std::size_t y, std::size_t rowSize)
    {
        return y + x * rowSize;
    }

    static constexpr auto idx(coord c, std::size_t rowSize)
    {
        auto [x, y] = c;
        return idx(x, y, rowSize);
    }

    static auto invidx(auto i, auto rowSize)
    {
        assert(rowSize > 0);
        auto x = i / rowSize;
        auto y = i % rowSize;
        return std::make_pair(x, y);
    }

    std::size_t idx(auto x, auto y) const { return idx(x, y, rowSize); }
    std::size_t idx(coord c) const { return idx(c, rowSize); }
    auto invidx(int i) const { return invidx(i, rowSize); }

    bool valid(std::size_t i) { return i < data.size(); }

    char nth(auto x, auto y) const
    {
        std::size_t i = idx(x, y);
        assert(i < data.size());
        return data[i];
    }

    char nth(coord c) const
    {
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

                if (node1 == '.' || node2 == '.') continue;
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
    const std::size_t r = 10;
    auto i = 13;
    auto c = input::invidx(13, r);
    constexpr auto idx = [r](auto c){ return input::idx(c, r); };
    constexpr auto invidx = [r](auto i){ return input::invidx(i, r); };
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

class enumerate : public std::ranges::range_adaptor_closure<enumerate> {
    const size_t m_start = 0;
public:
    enumerate() = default;
    enumerate(size_t s) : m_start(s) {}
    template<std::ranges::viewable_range R>
    auto operator()(R&& range) {
        return std::ranges::zip_view(std::views::iota(m_start), std::forward<R>(range));
    }
};

TEST(BasicTest, SetSize) {
    std::set<int> s{1,2,3};
    ASSERT_EQ(s.size(), 3);
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

    input.iterate(
        [&](coord antenna1c, coord antenna2c)
        {
            auto [antinode1c, antinode2c] = findAntinodes(antenna1c, antenna2c);
            auto antinode1i = input.idx(antinode1c);
            // I need to check if there is no antena over it
            std::cout << 
                "Iterating over antenas: " << input.get(antenna1c) << " " << antenna1c << " " << antenna2c << std::endl;
            if (input.valid(antinode1i) && input.get(antinode1i) == '.') {
                // std::cout << 
                //     "Found valid antinode 1 " << antinode1c << std::endl;
                antinodesIndexes.push_back(antinode1i);
            }
            auto antinode2i = input.idx(antinode2c);
            if (input.valid(antinode2i) && input.get(antinode2i) == '.') {
                // std::cout << 
                //     "Found valid antinode 2 " << antinode2c << std::endl;
                antinodesIndexes.push_back(antinode2i);
            }
        });

    // The missing antinode
    // plus an antinode overlapping the topmost A-frequency antenna:
    
    std::set<std::size_t> antinodesSet;
    antinodesSet.insert(antinodesIndexes.begin(), antinodesIndexes.end());

    std::cout << "Output: " << antinodesIndexes.size() << std::endl;
    std::cout << "Output: " << antinodesSet.size() << std::endl;
    return 0;
}
