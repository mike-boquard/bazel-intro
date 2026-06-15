#include <iostream>
#include "cpp/greeter/greeter.h"

int main(int argc, char* argv[]) {
    std::string name = (argc > 1) ? argv[1] : "World";
    std::cout << greeter::Hello(name) << std::endl;
    return 0;
}
