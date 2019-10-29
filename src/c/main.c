#include "client.h"

int main() 
{ 
    //int sockfd_data = open_connection(DATA_PORT);
    int sockfd_control = open_connection(CONTROL_PORT);
  
    write(sockfd_control, "Hello", strlen("Hello"));     
 
    //close(sockfd_data); 
    close(sockfd_control); 
} 
