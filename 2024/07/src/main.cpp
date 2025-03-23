#include <bitset>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <iostream>
#include <memory>
#include <numeric>
#include <ostream>
#include <stdexcept>
#include <vector>
#include <sstream>
#include <fstream>
#include <cassert>
#include <ranges>

#include <gtest/gtest.h>


template <typename T>
concept Streamable = requires(const T &s, std::ostream &os) { os << s; };

struct Line {
    std::uint64_t header;
    std::vector<std::uint64_t> numbers;
};

std::ostream& operator<<(std::ostream& os, const Line& line)
{
    os << "Line(" << line.header;
    for (const auto i : line.numbers) {
        os << "," << i;
    }
    os << ")";
    return os;
}

template <Streamable T>
std::ostream& operator<<(std::ostream& os, const std::vector<T>& vec)
{
    os << "std::vector<?>{";
    for (const auto& i : vec) {
        os << i << ", ";
    }
    os << "}";
    return os;
 }

template <typename T>
T pop(std::span<const T>& v) {
    assert(v.size() > 0);
    auto t = v.front();
    v = std::span(v.data() + 1, v.size() - 1);
    return t;
}

TEST(BasicTests, Pop)
{
    const auto v = std::vector{1,2,3};
    auto span = std::span(v);
    ASSERT_EQ(pop(span), 1);
    ASSERT_EQ(pop(span), 2);
    ASSERT_EQ(pop(span), 3);
}

template <typename T = std::uint64_t>
T to(std::string_view str)
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
    ASSERT_EQ(to<int>("10"), 10);
    ASSERT_EQ(to<int>("20"), 20);
    ASSERT_EQ(to<int>("0"), 0);
}

auto concat(auto n1, auto n2) -> decltype(auto)
{
    return to(std::format("{}{}", n1, n2));
}

TEST(BasicTests, Concat)
{
    ASSERT_EQ(concat(10, 10), 1010);
    ASSERT_EQ(concat(concat(1, 2), 3), 123);
    ASSERT_EQ(concat(3, concat(1, 2)), 312);
    ASSERT_EQ(concat(0, 1), 1);
    ASSERT_EQ(concat(1, 0), 10);
    ASSERT_EQ(concat(0, 0), 0);
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

void compute(std::uint64_t acc, std::span<const std::uint64_t> rest, std::vector<std::uint64_t>& output)
{
    //std::cout << "Computing " << acc << " " << rest << std::endl;
    if (rest.empty()) {
        output.push_back(acc);
        return;
    }

    std::uint64_t v = pop(rest);
    compute(acc + v, rest, output);
    compute(acc * v, rest, output);
    compute(concat(acc, v), rest, output);
}

auto compute(const std::vector<std::uint64_t>& rest) -> decltype(auto)
{
    assert(rest.size() > 0);
    auto span = std::span(rest);
    std::uint64_t top = pop(span);
    assert(top > 0);
    std::vector<std::uint64_t> output;
    compute(top, span, output);
    return output;
}

auto compute(const Line& line) -> decltype(auto)
{
    if (line.numbers.size() == 0) {
        std::ostringstream lineos;
        lineos << line;
        throw std::runtime_error(std::format("Line bug? {}", lineos.str()));
    }
    return compute(line.numbers);
}

bool computeLine(const Line& line)
{
    auto output = compute(line);
    return isIn(line.header, output);
}

auto parseLine(const auto& line)
{
    Line output;
    char colon;
    std::istringstream linestream(line);
    linestream >> output.header >> colon;
    for (std::uint64_t num; linestream >> num;) {
        output.numbers.push_back(num);
    }
    return output;
}

auto readinput(const auto& path)
{
    std::ifstream fil(path);
    std::string line;
    std::vector<Line> output;
    while (std::getline(fil, line)) {
        output.push_back(parseLine(line));
    }
    return output;
}

struct count: public std::ranges::view_interface<count> {
    size_t cnt = 0;
    size_t size;

    count(auto size) : size(size) {};

    
    auto begin() { return 0; }
    auto end() { return size; }
};

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

auto collect()
{
    return std::ranges::to<std::vector>();
}

int main(int argc, char* argv[])
{
    const char* run_tests = std::getenv("RUN_GTEST");
    if (run_tests != nullptr && std::string(run_tests) != "") {
        ::testing::InitGoogleTest(&argc, argv);
        return RUN_ALL_TESTS();
    }

    auto input = readinput(argv[1]);

    std::uint64_t output = 0;
    for (auto [i, line] : input | enumerate(1) | collect()) {
        if (computeLine(line)) {
            output += line.header;
        }
    }

    std::cout << "Output: " << output << std::endl;
    return 0;
}
