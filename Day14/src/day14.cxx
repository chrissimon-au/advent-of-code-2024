#include <catch2/catch_test_macros.hpp>
#include <vector>
#include <string>
#include <iostream>

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
    Coordinates(int x, int y) : x_(x), y_(y) {}
    const int x() const { return x_; }
    const int y() const { return y_; }
};

std::ostream & operator << (std::ostream & outs, const Coordinates & coords) {
    return outs << "(" << coords.x() << ", " << coords.y() << ")";
}

class Velocity : public Coordinates {
public:
    Velocity(int x, int y) : Coordinates(x,y) {}
    Velocity operator*(int multiplier) {
        return Velocity(x_ * multiplier, y_ * multiplier);
    }
};

class Position : public Coordinates {
public:
    Position(int x, int y) : Coordinates(x,y) {}
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
    const Position position() const { return position_; }

    void move_seconds(int seconds, Position map_size) { 
        std::cout << "Moving from " << position_ << " with " << seconds << ", " << velocity_ << " wrapping at " << map_size << ":" << std::endl;
        position_.move_by(velocity_ * seconds, map_size);
        std::cout << "  " << position_ << std::endl;
    }
};

class Map {
private:
    Position size_;
    std::vector<Robot> robots_;
public:
    Map(Position size) : size_(size) {}
    void move_seconds(int seconds) {
    for (auto r : robots_)
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
        for (auto r : robots_)
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
        std::cout << "top_left: " << top_left << "; top_right: " << top_right
        return top_left * top_right * bottom_left * bottom_right;
    }
    void add_robot(const Robot robot) {
        robots_.push_back(robot);
    }
};

int get_safety_score(std::string input, Position size) {
    return 0;
}

TEST_CASE( "Single Robot, Single Dimension" ) {
//     SECTION( "From Input" ) {
//         std::string input = "p=0,4 v=1,0";
//         Position map_size = Position(7,5);
//         std::cout << map_size << std::endl;
//         REQUIRE( get_safety_score(input, map_size) == 0 );
//     }

    SECTION( "Direct Robot" ) {

//         SECTION( "moving a single time unit" ) {
//             Position map_size = Position(7,5);
//             Position position = Position(0,4);
//             Velocity velocity = Velocity(1,0);
//             Robot r = Robot(position, velocity);

//             r.move_seconds(1, map_size);

//             REQUIRE( r.position().x() == 1 );
//             REQUIRE( r.position().y() == 4 );
//         }

//         SECTION( "moving multiple time units" ) {
//             Position map_size = Position(7,5);
//             Position position = Position(0,4);
//             Velocity velocity = Velocity(1,0);
//             Robot r = Robot(position, velocity);

//             r.move_seconds(4, map_size);

//             REQUIRE( r.position().x() == 4 );
//             REQUIRE( r.position().y() == 4 );
//         }

//         SECTION( "moving multiple time units and wrapping" ) {
//             Position map_size = Position(7,5);
//             Position position = Position(0,4);
//             Velocity velocity = Velocity(1,0);
//             Robot r = Robot(position, velocity);

//             r.move_seconds(8, map_size);

//             REQUIRE( r.position().x() == 1 );
//             REQUIRE( r.position().y() == 4 );
//         }

//         SECTION( "moving in both directions and wrapping" ) {
//             Position map_size = Position(7,5);
//             Position position = Position(0,4);
//             Velocity velocity = Velocity(1,3);
//             Robot r = Robot(position, velocity);

//             r.move_seconds(8, map_size);

//             REQUIRE( r.position().x() == 1 );
//             REQUIRE( r.position().y() == 3 );
//         }

        // SECTION( "moving backwards" ) {
        //     Position map_size = Position(7,5);
        //     Position position = Position(0,4);
        //     Velocity velocity = Velocity(-1,-3);
        //     Robot r = Robot(position, velocity);

        //     r.move_seconds(2, map_size);

        //     REQUIRE( r.position().x() == 5 );
        //     REQUIRE( r.position().y() == 3 );
        // }

    }
}

TEST_CASE( "Map can compute safety score" ) {
    // SECTION( "1 Robot in each quadrant" ) {
    //     Map map = Map(Position(7,5));
    //     map.add_robot(Robot(Position(0,0), Velocity(0,0)));
    //     map.add_robot(Robot(Position(6,0), Velocity(0,0)));
    //     map.add_robot(Robot(Position(0,4), Velocity(0,0)));
    //     map.add_robot(Robot(Position(6,4), Velocity(0,0)));

    //     REQUIRE( map.safety_score() == 1 );
    // }

    // SECTION( "2 Robot in each quadrant" ) {
    //     Map map = Map(Position(7,5));
    //     map.add_robot(Robot(Position(0,0), Velocity(0,0)));
    //     map.add_robot(Robot(Position(1,1), Velocity(0,0)));
    //     map.add_robot(Robot(Position(6,0), Velocity(0,0)));
    //     map.add_robot(Robot(Position(5,1), Velocity(0,0)));
    //     map.add_robot(Robot(Position(0,4), Velocity(0,0)));
    //     map.add_robot(Robot(Position(1,3), Velocity(0,0)));
    //     map.add_robot(Robot(Position(6,4), Velocity(0,0)));
    //     map.add_robot(Robot(Position(5,3), Velocity(0,0)));

    //     REQUIRE( map.safety_score() == 16 );
    // }

    // SECTION( "Robot on centre line don't count" ) {
    //     Map map = Map(Position(7,5));
    //     map.add_robot(Robot(Position(0,0), Velocity(0,0)));
    //     map.add_robot(Robot(Position(3,1), Velocity(0,0)));
    //     map.add_robot(Robot(Position(6,0), Velocity(0,0)));
    //     map.add_robot(Robot(Position(3,1), Velocity(0,0)));
    //     map.add_robot(Robot(Position(0,4), Velocity(0,0)));
    //     map.add_robot(Robot(Position(1,2), Velocity(0,0)));
    //     map.add_robot(Robot(Position(6,4), Velocity(0,0)));
    //     map.add_robot(Robot(Position(5,2), Velocity(0,0)));

    //     REQUIRE( map.safety_score() == 1 );
    // }

    SECTION( "AoC Sample Case" ) {
        Map map = Map(Position(11,7));
        map.add_robot(Robot(Position(0,4), Velocity(3,-3)));
        map.add_robot(Robot(Position(6,3), Velocity(-1,-3)));
        map.add_robot(Robot(Position(10,3), Velocity(-1,2)));
        map.add_robot(Robot(Position(2,0), Velocity(2,-1)));
        map.add_robot(Robot(Position(0,0), Velocity(1,3)));
        map.add_robot(Robot(Position(3,0), Velocity(-2,-2)));
        map.add_robot(Robot(Position(7,6), Velocity(-1,-3)));
        map.add_robot(Robot(Position(3,0), Velocity(-1,-2)));
        map.add_robot(Robot(Position(9,3), Velocity(2,3)));
        map.add_robot(Robot(Position(7,3), Velocity(-1,2)));
        map.add_robot(Robot(Position(2,4), Velocity(2,-3)));
        map.add_robot(Robot(Position(9,5), Velocity(-3,-3)));

        map.move_seconds(100);

        REQUIRE(map.safety_score() == 12);
    }
}