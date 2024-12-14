#include <catch2/catch_test_macros.hpp>
#include <vector>
#include <string>
#include <iostream>
#include <regex>
#include <filesystem>
#include <fstream>

namespace fs = std::filesystem;

std::string readFile(fs::path path)
{
    // Open the stream to 'lock' the file.
    std::ifstream f(path, std::ios::in | std::ios::binary);

    // Obtain the size of the file.
    const auto sz = fs::file_size(path);

    // Create a buffer.
    std::string result(sz, '\0');

    // Read the whole file into the buffer.
    f.read(result.data(), sz);

    return result;
}

int mod(int a, int b)
{
  int i = a%b;
  if(i<0) i+=b;
  return i;
}

class Coordinates {
protected:
    int x_;
    int y_;
public:
    Coordinates() {}
    Coordinates(int x, int y) : x_(x), y_(y) {}
    int x() const { return x_; }
    int y() const { return y_; }
};

std::ostream & operator << (std::ostream & outs, const Coordinates& coords) {
    return outs << "(" << coords.x() << ", " << coords.y() << ")";
}

class Velocity : public Coordinates {
public:
    Velocity(int x, int y) : Coordinates(x,y) {}
    Velocity() : Coordinates(0,0) {}
    Velocity operator*(int multiplier) {
        return Velocity(x_ * multiplier, y_ * multiplier);
    }
};

class Position : public Coordinates {
public:
    Position(int x, int y) : Coordinates(x,y) {}
    Position() : Coordinates(0,0) {}
    void move_by(Velocity velocity, Position wrap_at) {
        x_ = mod((x_ + velocity.x()), wrap_at.x());
        y_ = mod((y_ + velocity.y()), wrap_at.y());
    }
};

class Robot {
private:
    Position position_;
    Velocity velocity_;
public:
    Robot(Position position, Velocity velocity) : position_(position), velocity_(velocity) {}
    Robot(std::string definition) {
        std::regex const re("p=(\\d+),(\\d+) v=([-\\d]+),([-\\d]+)");
        std::smatch m;
        if(std::regex_match(definition, m, re))
        {
            position_ = Position(std::stoi(m[1].str()), std::stoi(m[2].str()));
            velocity_ = Velocity(std::stoi(m[3].str()), std::stoi(m[4].str()));
        }
    };
    Position position() { return position_; }
    Velocity velocity() { return velocity_; }

    void move_seconds(int seconds, Position map_size) { 
        position_.move_by(velocity_ * seconds, map_size);
    }
};

class Map {
private:
    Position size_;
    std::vector<Robot> robots_;
public:
    Map(Position size) : size_(size) {}
    void load_robots(std::string definitions) {
        std::istringstream iss(definitions);
        for (std::string line; std::getline(iss, line); )
        {
            this->add_robot(Robot(line));
        }
    }
    void move_seconds(int seconds) {
        for (auto &r : robots_)
        {
            r.move_seconds(seconds, size_);
        }
    }
    int safety_score() {
        int top_left = 0;
        int top_right = 0;
        int bottom_left = 0;
        int bottom_right = 0;
        int middle_x = (size_.x()-1) / 2;
        int middle_y = (size_.y()-1) / 2;
        for (auto &r : robots_)
        {
            Position pos = r.position();
            if (pos.x() < middle_x && pos.y() < middle_y) {
                top_left++;
            }
            if (pos.x() < middle_x && pos.y() > middle_y) {
                bottom_left++;
            }
            if (pos.x() > middle_x && pos.y() < middle_y) {
                top_right++;
            }
            if (pos.x() > middle_x && pos.y() > middle_y) {
                bottom_right++;
            }
        }
        return top_left * top_right * bottom_left * bottom_right;
    }
    void add_robot(Robot robot) {
        robots_.push_back(robot);
    }
};

int get_safety_score(std::string input, Position size) {
    return 0;
}

TEST_CASE( "Single Robot, Single Dimension" ) {
    SECTION( "From Input" ) {
        std::string input = "p=0,4 v=1,0";
        Position map_size = Position(7,5);
        REQUIRE( get_safety_score(input, map_size) == 0 );
    }

    SECTION( "Direct Robot" ) {

        SECTION( "moving a single time unit" ) {
            Position map_size = Position(7,5);
            Position position = Position(0,4);
            Velocity velocity = Velocity(1,0);
            Robot r = Robot(position, velocity);

            r.move_seconds(1, map_size);

            REQUIRE( r.position().x() == 1 );
            REQUIRE( r.position().y() == 4 );
        }

        SECTION( "moving multiple time units" ) {
            Position map_size = Position(7,5);
            Position position = Position(0,4);
            Velocity velocity = Velocity(1,0);
            Robot r = Robot(position, velocity);

            r.move_seconds(4, map_size);

            REQUIRE( r.position().x() == 4 );
            REQUIRE( r.position().y() == 4 );
        }

        SECTION( "moving multiple time units and wrapping" ) {
            Position map_size = Position(7,5);
            Position position = Position(0,4);
            Velocity velocity = Velocity(1,0);
            Robot r = Robot(position, velocity);

            r.move_seconds(8, map_size);

            REQUIRE( r.position().x() == 1 );
            REQUIRE( r.position().y() == 4 );
        }

        SECTION( "moving in both directions and wrapping" ) {
            Position map_size = Position(7,5);
            Position position = Position(0,4);
            Velocity velocity = Velocity(1,3);
            Robot r = Robot(position, velocity);

            r.move_seconds(8, map_size);

            REQUIRE( r.position().x() == 1 );
            REQUIRE( r.position().y() == 3 );
        }

        SECTION( "moving backwards" ) {
            Position map_size = Position(7,5);
            Position position = Position(0,4);
            Velocity velocity = Velocity(-1,-3);
            Robot r = Robot(position, velocity);

            r.move_seconds(2, map_size);

            REQUIRE( r.position().x() == 5 );
            REQUIRE( r.position().y() == 3 );
        }

        SECTION( "Parsing from definition" ) {
            Robot r = Robot("p=6,3 v=-1,-3");

            REQUIRE( r.position().x() == 6 );
            REQUIRE( r.position().y() == 3 );
            REQUIRE( r.velocity().x() == -1 );
            REQUIRE( r.velocity().y() == -3 );
        }

    }
}

TEST_CASE( "Map can compute safety score" ) {

    SECTION( "Parsing robots into map" ) {
        Map map = Map(Position(7,5));
        map.load_robots("p=0,0 v=0,0\np=6,0 v=0,0\np=0,4 v=0,0\np=6,4 v=0,0");
        REQUIRE( map.safety_score() == 1 );
    }

    SECTION( "1 Robot in each quadrant" ) {
        Map map = Map(Position(7,5));
        map.add_robot(Robot(Position(0,0), Velocity(0,0)));
        map.add_robot(Robot(Position(6,0), Velocity(0,0)));
        map.add_robot(Robot(Position(0,4), Velocity(0,0)));
        map.add_robot(Robot(Position(6,4), Velocity(0,0)));

        REQUIRE( map.safety_score() == 1 );
    }

    SECTION( "2 Robot in each quadrant" ) {
        Map map = Map(Position(7,5));
        map.add_robot(Robot(Position(0,0), Velocity(0,0)));
        map.add_robot(Robot(Position(1,1), Velocity(0,0)));
        map.add_robot(Robot(Position(6,0), Velocity(0,0)));
        map.add_robot(Robot(Position(5,1), Velocity(0,0)));
        map.add_robot(Robot(Position(0,4), Velocity(0,0)));
        map.add_robot(Robot(Position(1,3), Velocity(0,0)));
        map.add_robot(Robot(Position(6,4), Velocity(0,0)));
        map.add_robot(Robot(Position(5,3), Velocity(0,0)));

        REQUIRE( map.safety_score() == 16 );
    }

    SECTION( "Robot on centre line don't count" ) {
        Map map = Map(Position(7,5));
        map.add_robot(Robot(Position(0,0), Velocity(0,0)));
        map.add_robot(Robot(Position(3,1), Velocity(0,0)));
        map.add_robot(Robot(Position(6,0), Velocity(0,0)));
        map.add_robot(Robot(Position(3,1), Velocity(0,0)));
        map.add_robot(Robot(Position(0,4), Velocity(0,0)));
        map.add_robot(Robot(Position(1,2), Velocity(0,0)));
        map.add_robot(Robot(Position(6,4), Velocity(0,0)));
        map.add_robot(Robot(Position(5,2), Velocity(0,0)));

        REQUIRE( map.safety_score() == 1 );
    }

    SECTION( "AoC Sample Case" ) {
        Map map = Map(Position(11,7));
        std::string robot_definitions = readFile("../sampledata.txt");
        int answer = std::stoi(readFile("../sampledata.answer.txt"));

        map.load_robots(robot_definitions);
        map.move_seconds(100);

        REQUIRE(map.safety_score() == answer);
    }

    SECTION( "AoC Test Case" ) {
        Map map = Map(Position(101,103));
        std::string robot_definitions = readFile("../testdata.txt");
        int answer = std::stoi(readFile("../testdata.answer.txt"));

        map.load_robots(robot_definitions);
        map.move_seconds(100);

        REQUIRE(map.safety_score() == answer);
    }
}