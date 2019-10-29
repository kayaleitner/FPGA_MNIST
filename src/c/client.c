#include "client.h"

int open_connection(uint16_t port)
{
    int sockfd; 
    struct sockaddr_in servaddr; 
   
    sockfd = socket(AF_INET, SOCK_STREAM, 0); 
    if (sockfd == -1) { 
        fprintf(stderr, "Could not create socket.\n"); 
        exit(0); 
    } 

    memset(&servaddr, 0, sizeof(servaddr)); 
   
    servaddr.sin_family = AF_INET; 
    servaddr.sin_addr.s_addr = inet_addr("192.168.56.1"); 
    servaddr.sin_port = htons(port); 
  
    if (connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr)) != 0) { 
        fprintf(stderr, "Could not connect with server.\n"); 
        exit(0); 
    }

    return sockfd;
}

