#include "cpp/greeter/greeter.h"
#include "spdlog/spdlog.h"
#include <iostream>

int main(int argc, char *argv[]) {
    std::string name = (argc > 1) ? argv[1] : "World";
    spdlog::info("Saying hello to: {}", name);
    std::cout << greeter::Hello(name) << std::endl;
    return 0;
}
