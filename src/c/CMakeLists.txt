cmake_minimum_required(VERSION 3.0)
project(FPGA_MNIST)


# Define the main executable
add_executable(client_demo main.c client.c)