#include <cstdlib>
#include <algorithm>
#include <cassert>
#include <cmath>
#include <filesystem>
#include <functional>
#include <iostream>
#include <fstream>
#include <ostream>
#include <ranges>
#include <stdexcept>
#include <thread>
#include <utility>
#include <vector>
#include <expected>


// Parsed input type
using input = std::vector<std::vector<char>>;

// Parse the input string into nested std::vector
input readinput(std::string path) {
    std::ifstream file(path);
    if (!file.is_open()) {
        throw std::filesystem::filesystem_error(
            "File not found",
            make_error_code(std::errc::no_such_file_or_directory)
        );
    }

    std::string line;
    std::vector<std::vector<char>> lines;
    while (getline(file, line)) {
        std::vector<char> linevec(line.begin(), line.end());
        linevec.push_back('\n');
        lines.push_back(linevec);
    }
    return lines;
}

template<typename T>
std::ostream& operator<<(std::ostream& os, const std::vector<T>& vec) {
    for (auto item : vec) {
       os << item;
    }
    return os;
}

// print generic tuple
template<typename... Args>
std::ostream& operator<<(std::ostream& os, const std::tuple<Args...>& t) {
    os << "(";
    std::apply([&os](const auto&... args) {
        ((os << args << ','), ...);
    }, t);
    os << ")";
    return os;
}

template<typename T>
std::ostream& operator<<(std::ostream& os, const std::optional<T>& op) {
    if (op) {
        os << op.value();
    }
    return os;
}

struct point {
    std::size_t x, y;
    char ch;
};

std::ostream& operator<<(std::ostream& os, const point& p) {
    os << "(" << p.x << "," << p.y << "," << p.ch << ")";
    return os;
}

struct matrix {
    matrix(const input&& inp) : m_mat(std::move(inp)) {
        auto find_func = [](char ch) { return ch == '^' || ch == 'v' || ch == '<' || ch == '>'; };
        if (auto p = find(find_func)) {
            m_pos = p.value();
        }
    }

    size_t run() {
        std::cout << "Running " << std::endl;
        while (step()) {
            render();
        };

        return m_steps;
    }

private:

    void render() {
#if DEBUG_RENDER
        system("clear");
        std::cout << "Step " << m_steps << std::endl;
        std::cout << *this;
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
#endif
    }
    bool step() {
        auto newpos = move(m_pos);
        char square = get(newpos);

        switch (square) {
            case '.':
                ++m_steps;
                // no break! falling through into below case
            case 'X':
                update_map(newpos, m_pos.ch);
                m_pos = newpos;
                break;
            case '#':
                m_pos.ch = turn(m_pos.ch);
                update_map(m_pos, m_pos.ch);
                break;
            case '\0':
                // we reached the out of the map
                ++m_steps;
                return false;
            default:
                throw std::invalid_argument(std::format("Unexpected value in step {}", square));
        }

        return true;
    }

    static char turn(char ch) {
        switch (ch) {
            case '^':
                return '>';
            case '>':
                return 'v';
            case 'v':
                return '<';
            case '<':
                return '^';
            default:
                throw std::invalid_argument(std::format("Invalid argument to turn {}", ch));
        }
    }

    static bool valid(const char direction) {
        switch (direction) {
            case '^':
            case '>':
            case 'v':
            case '<':
                return true;
            default:
                return false;
        }
    }

    bool valid(const point& newpos) const {
        return max_rows() > newpos.x && max_columns() > newpos.y;
    }

    // Update the map with X to keep a record
    // of the visited squares
    void update_map(const point& p, char ch) {
        if (!valid(ch)) {
            throw std::invalid_argument(std::format("Invalid argument for update_map {}", ch));
        }
        if (valid(p)) {
            auto [x, y, _] = p;
            auto [oldx, oldy, __] = m_pos;
            m_mat[oldx][oldy] = 'X';
            m_mat[x][y] = ch;
        }
    }

    // Returns a new position, possibly invalid
    static point move(const point& pos) {
        point copy = pos;
        switch (pos.ch) {
            case '^':
                --copy.x;
                break;
            case '>':
                ++copy.y;
                break;
            case 'v':
                ++copy.x;
                break;
            case '<':
                --copy.y;
                break;
            default:
                throw std::invalid_argument(std::format("Invalid argument to move {}", pos.ch));
                break;
        }
        return copy;
    }


    // get a square in the table
    //
    // Returns:
    //   . -> non-visited square
    //   # -> an obstacle
    //   X -> a visited square
    char get(const point& pos) const {
        if (valid(pos)) {
            auto ch  = m_mat[pos.x][pos.y];
            switch (ch) {
                case '.':
                    return '.';
                case '#':
                    return '#';
                case 'X':
                    return 'X';
                default:
                    throw std::invalid_argument(std::format("Invalid argument to get {}", ch));
            }
        } else {
            return '\0';
        }
    }

    size_t max_columns() const {
        if (m_mat.size() == 0) {
            return 0;
        }

        return m_mat[0].size();
    }

    size_t max_rows() const {
        return m_mat.size();
    }

    const std::vector<char>& row(int x) {
        return m_mat[x];
    }

    std::optional<point> find(
        std::function<bool(char ch)> cb) {
        for (std::size_t x = 0; x < m_mat.size(); ++x) {
            for (std::size_t y = 0; y < m_mat[x].size(); ++y) {
                const char ch = m_mat[x][y];
                if (cb(ch)) {
                    return point{x, y, ch};
                }
            }
        }
        return std::nullopt;
    }

    uint64_t m_steps = 0;
    struct point m_pos;
    std::vector<std::vector<char>> m_mat;
    friend std::ostream& operator<<(std::ostream& os, const matrix& m);
};

std::ostream& operator<<(std::ostream& os, const matrix& m) {
    if (m.m_mat.empty()) {
        return os;
    }

    os << "      ";
    auto columns =  m.max_columns()-1;
    auto range = std::views::iota(0u, columns);
    std::ranges::for_each(range, [&os](auto i){
        os << i % 10;
    });
    os << std::endl;
    os << "      ";
    // Creates the horizontal bar
    auto hbar = std::ranges::views::repeat('\'')
        | std::views::take(columns)
        | std::ranges::to<std::string>();
    os << hbar << std::endl;
    for (auto i = 0; i < m.m_mat.size(); ++i) {
        os << std::format("{: 3} - ", i);
        for (auto j = 0; j < m.m_mat.size(); ++j) {
            os << m.m_mat[i][j];
        }
        os << std::endl;
    }
    return os;
}


int main(int argc, char* argv[]) {

    auto inp = matrix(readinput(argv[1]));
    int column = 4;
    // std::cout << "Input" << std::endl << inp << std::endl;
    auto output = inp.run();
    std::cout << "Output: " << output << std::endl;
    return 0; 
}
