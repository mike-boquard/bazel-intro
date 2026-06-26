#include <iostream>
#include <string>

#include "proto/greeter.grpc.pb.h"
#include <grpcpp/grpcpp.h>

// GreeterServiceImpl handles incoming SayHello RPCs.
class GreeterServiceImpl final : public greeter::GreeterService::Service {
    // ServerContext is unused here; leaving the parameter unnamed avoids an
    // -Wunused-parameter warning while still matching the override signature.
    grpc::Status SayHello(grpc::ServerContext * /*context*/, const greeter::HelloRequest *request,
                          greeter::HelloReply *reply) override {
        reply->set_message("Hello, " + request->name() + "!");
        return grpc::Status::OK;
    }
};

int main() {
    std::string addr = "0.0.0.0:50051";
    GreeterServiceImpl service;

    grpc::ServerBuilder builder;
    builder.AddListeningPort(addr, grpc::InsecureServerCredentials());
    builder.RegisterService(&service);

    auto server = builder.BuildAndStart();
    // BuildAndStart returns nullptr if the port is already in use; bail out
    // before claiming to listen so the integration test fails cleanly.
    if (!server) {
        std::cerr << "Failed to start server on " << addr << std::endl;
        return 1;
    }
    // Print to stdout so the integration test can detect startup.
    std::cout << "Listening on " << addr << std::endl;
    server->Wait();
    return 0;
}
