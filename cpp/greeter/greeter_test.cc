#include "cpp/greeter/greeter.h"
#include "gtest/gtest.h"

TEST(GreeterTest, HelloWithName) { EXPECT_EQ(greeter::Hello("World"), "Hello, World!"); }

TEST(GreeterTest, HelloWithEmptyString) { EXPECT_EQ(greeter::Hello(""), "Hello, !"); }

TEST(GreeterTest, HelloWithUnicode) { EXPECT_EQ(greeter::Hello("日本語"), "Hello, 日本語!"); }
