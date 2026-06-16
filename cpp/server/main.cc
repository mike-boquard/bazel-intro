#include <iostream>
#include <memory>
#include <string>

#include <grpcpp/grpcpp.h>
#include "proto/greeter.grpc.pb.h"

// GreeterServiceImpl handles incoming SayHello RPCs.
class GreeterServiceImpl final : public greeter::GreeterService::Service {
  grpc::Status SayHello(grpc::ServerContext* context,
                        const greeter::HelloRequest* request,
                        greeter::HelloReply* reply) override {
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
  // Print to stdout so the integration test can detect startup.
  std::cout << "Listening on " << addr << std::endl;
  server->Wait();
  return 0;
}
