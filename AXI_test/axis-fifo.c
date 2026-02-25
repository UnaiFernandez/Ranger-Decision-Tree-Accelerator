#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>
#include <sys/wait.h>
#include <time.h>
#include <signal.h>
#include <poll.h>
#include <sys/ioctl.h>

#define MAX_BUF_SIZE 508
#define NUM_INFERENCES 20

#define DIV 2
static volatile int running = 1;

uint32_t * mem_layout = NULL;                                         
uint32_t num_inputs = 0;                        
uint32_t num_labels = 0;                        
uint32_t labels_base = 0;
uint32_t divisor = 1;

static void signal_handler(int signal) {
    switch (signal) {
        case SIGINT:
        case SIGTERM:
        case SIGQUIT:
            running = 0;
            break;

        default:
            break;
    }
}

uint32_t * divide_data(uint32_t full_size, uint32_t divided_in) {
    uint32_t * sizes;                                 
    uint32_t standard, plus;      
    uint32_t i;                                     

    sizes = malloc(divided_in * sizeof(uint32_t));
    standard = full_size / divided_in;                           
    plus = standard + (full_size % divided_in);       

    for(i=0; i<divided_in-1; i++){                  
        sizes[i] = standard;                                    
    }                                             
    sizes[divided_in-1] = plus;                                  

    return sizes;                 

}  


void get_mem_layout(char * filename){
    FILE * fd_mem;
    uint32_t data, i = 0;


    if((fd_mem = fopen(filename, "r")) == NULL){
        printf("[ERROR] Opening mem layout file: %s", strerror(errno));
    }

    fscanf(fd_mem, "%X", &data);
    num_inputs = data;

    //fscanf(fd_mem, "%X", &data);
    //num_labels = data;
    
    mem_layout = malloc((num_inputs) * sizeof(uint32_t));
    
    while(!feof(fd_mem) && i < num_inputs){
        fscanf(fd_mem, "%X", &data);
        mem_layout[i] = data;
        i++;
    }

    num_labels = mem_layout[0];
    
    labels_base = num_inputs - num_labels;
    
    fclose(fd_mem);
}


void * write_axis_fifo(void * arg){                                    
    int fd_w, i, j;                                                        
    int start_addr = 0;                   
    ssize_t bytes_wr;                                       
    uint32_t * sizes;                                              

    printf("[INFO] Thread 1 (write fifo)\n");          
    
 

    fd_w = *(int *)arg;               



    sizes = divide_data(num_inputs, divisor);                                  

    i = 0;
    printf("[*] Sending data ...");
    while(i < divisor){                                         
        // Write to file                                       
        bytes_wr = write(fd_w, mem_layout + start_addr, sizes[i]*sizeof(uint32_t));
        //printf("start_adr: %d\n", start_addr);
        for(j = 0; j < 10; j++){     
            //printf("%X ", mem_layout[j + start_addr]);
            //printf(".");
            //printf("addr =  %d + %d\n", start_addr, j);
        }                                                
        usleep(100);                          
        //i += MAX_BUF_SIZE;                                           
        start_addr += sizes[i];                           
        i++;                                                 
    }                                                              
    printf("\n");                                                          

    close(fd_w);                                                           
    pthread_exit(NULL);                                       
}

void * read_axis_fifo(void * arg){                                                         
    int fd_r, i, j;                               
    uint32_t * out_buff;                                                   
    uint32_t output_size;                                     
    ssize_t bytes_rd;                                            

    printf("[INFO] Thread 2 (read fifo)\n");                                                  

    fd_r = *(int*)arg;                                                     
    output_size = num_labels + 1;                                         
    out_buff = malloc(output_size*sizeof(uint32_t));             

    //while(i < num_inputs){                                                           
    //while(running){                             
    sleep(1);                                                              

    bytes_rd = read(fd_r, out_buff, output_size*sizeof(uint32_t));
    if(bytes_rd > 0){                                      
        printf("[*] Receiving data: ");                                       
        for(j = 0; j < 10; j++){
            printf("(%X) ", out_buff[j]);                  
        }                 
        printf("... ");
        printf("Bytes read: %d\n", bytes_rd);                 
    }                                                      
    //}                                                                                
    float avg_c_time = (out_buff[num_labels]/(float)num_labels)*10.0;
    printf("--------------------------------------\n");
    printf("[*] Total cycles: %d\n", out_buff[num_labels]);
    printf("[*] Average inference time: %0.2f ns\n", avg_c_time);

    int c = 0;

    for(int j = 0; j < num_labels; j++){
        if(out_buff[j] == mem_layout[labels_base + j]){
            c++;
        }
    }
    float acc = (c * 100.0)/(float)num_labels;
    printf("[*] Accuracy: %0.2f \% (%d/%d)\n", acc, c, num_labels);

    free(out_buff);                                           
    pthread_exit(NULL);                                                   
}

int main(int argc, char ** argv){

    pthread_t th1, th2;
    int fd_w, fd_r;

    printf("    ___   _  __ _________       __            __ \n");
    printf("   /   | | |/ //  _/ ___/      / /____  _____/ /_\n");
    printf("  / /| | |   / / / \\__ \\______/ __/ _ \\/ ___/ __/\n");
    printf(" / ___ |/   |_/ / ___/ /_____/ /_/  __(__  ) /_  \n");
    printf("/_/  |_/_/|_/___//____/      \\__/\\___/____/\\__/  \n\n");


    if((fd_w = open("/dev/axis_fifo_0x43c00000", O_WRONLY)) == -1){
        printf("[ERROR] Opening file: %s", strerror(errno));
        pthread_exit(NULL);
    }
    if((fd_r = open("/dev/axis_fifo_0x43c00000", O_RDONLY)) == -1){
        printf("[ERROR] Opening file: %s", strerror(errno));
        pthread_exit(NULL);
    }

    printf("[INFO] File: %s\n", argv[1]);

    //get_mem_layout("./mem_layout.txt");   
    get_mem_layout(argv[1]);   
    divisor = atoi(argv[2]);

    //Create threads
    pthread_create(&th1, NULL, write_axis_fifo, (void *) &fd_w);
    pthread_create(&th2, NULL, read_axis_fifo, (void *) &fd_r);

    //while(running){
    //	sleep(1);
    //}

    //printf("Bye bye ...\n");
    free(mem_layout);                             
    pthread_join(th1, NULL);
    pthread_join(th2, NULL);

    return 0;
}
