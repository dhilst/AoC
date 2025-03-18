#include <bitset>
#include <cmath>
#include <iostream>
#include <memory>
#include <numeric>
#include <ostream>
#include <vector>
#include <sstream>
#include <fstream>
#include <cassert>
#include <ranges>


template <typename T>
concept Streamable = requires(const T &s, std::ostream &os) { os << s; };

using HeaderType = std::uint64_t;

struct Line {
    HeaderType header;
    std::vector<HeaderType> numbers;
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
T pop(std::vector<T>& v) {
    assert(v.size() > 0);
    auto t = v.front();
    v.erase(v.begin());
    return t;
}

bool isIn(auto value, auto& vec) {
    return std::find(vec.begin(), vec.end(), value) != vec.end();
}

inline std::vector<HeaderType> range(size_t n)
{
    std::vector<HeaderType> output(n);
    std::iota(output.begin(), output.end(), 0);
    return output;
}

void compute(HeaderType acc, std::vector<HeaderType>& rest, std::vector<HeaderType>& output)
{
    //std::cout << "Computing " << acc << " " << rest << std::endl;
    if (rest.empty()) {
        output.push_back(acc);
        return;
    }

    auto copy = std::vector(rest); // copy
    HeaderType v = pop(copy);
    compute(acc + v, copy, output);
    compute(acc * v, copy, output);
}

auto compute(std::vector<HeaderType>& rest) -> decltype(auto)
{
    assert(rest.size() > 0);
    HeaderType v = pop(rest);
    assert(v > 0);
    std::vector<HeaderType> output;
    compute(v, rest, output);
    return output;
}

auto compute(const Line& line) -> decltype(auto)
{
    auto numbers = line.numbers; // copy
    if (numbers.size() == 0) {
        std::ostringstream lineos;
        lineos << line;
        throw std::runtime_error(std::format("Line bug? {}", lineos.str()));
    }
    return compute(numbers);
}

bool computeLine(const Line& line)
{
    auto output = compute(line);
    auto value = isIn(line.header, output);
    return value;
}

auto parseLine(const auto& line)
{
    Line output;
    char colon;
    std::istringstream linestream(line);
    linestream >> output.header >> colon;
    for (HeaderType num; linestream >> num;) {
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
    auto input = readinput(argv[1]);

    HeaderType output = 0;
    for (auto [i, line] : input | enumerate(1) | collect()) {
        if (computeLine(line)) {
            output += line.header;
        }
    }

    std::cout << "Output: " << output << std::endl;
    return 0;
}
