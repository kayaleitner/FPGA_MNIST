#include "client.h"
#include "dbg.h"

int main() 
{
    log_info("Starting client");

    //int sockfd_data = open_connection(DATA_PORT);
    int sockfd_control = open_connection(CONTROL_PORT);


    write(sockfd_control, "Hello", strlen("Hello"));     

    //close(sockfd_data); 
    close(sockfd_control);
    log_info("Closing Socket. End");
} 
