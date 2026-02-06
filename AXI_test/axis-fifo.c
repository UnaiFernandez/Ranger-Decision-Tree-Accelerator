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
#define DIV 2
static volatile int running = 1;

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

uint32_t get_num_inputs(char * filename){
	FILE * fd_mem;
	uint32_t num_inputs;

	if((fd_mem = fopen(filename, "r")) == NULL){
		printf("[ERROR] Mem layout file: %s", strerror(errno));
	}

	fscanf(fd_mem, "%X", &num_inputs);
	printf("Num inputs: %d (%X)\n", num_inputs, num_inputs);

	fclose(fd_mem);

	return num_inputs;
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


uint32_t * get_mem_layout(char * filename, uint32_t num_inputs){
	FILE * fd_mem;
	uint32_t data, i = 0;
	uint32_t * mem_layout;

	mem_layout = malloc(num_inputs * sizeof(uint32_t));

	if((fd_mem = fopen(filename, "r")) == NULL){
		printf("[ERROR] Opening mem layout file: %s", strerror(errno));
	}

	fscanf(fd_mem, "%X", &num_inputs); // Read and ignore the first
	while(!feof(fd_mem) && i < num_inputs){
		fscanf(fd_mem, "%X", &data);
		mem_layout[i] = data;
		i++;
	}

	//for(i = 0; i < num_inputs; i++){
	//	printf("%X ", mem_layout[i]);
	//}
	//printf("\n");

	fclose(fd_mem);

	return mem_layout;
}


void * write_axis_fifo(void * arg){                                    
        uint32_t * mem_layout;                                         
        uint32_t num_inputs;                        
        int fd_w, i, j;                                                        
        int start_addr;                   
        ssize_t bytes_wr;                                       
        uint32_t * sizes;                                              
                                                                       
        printf("Thread 1 (write fifo)\n");          
                                                                               
        fd_w = *(int *)arg;               
                                                                
        num_inputs = get_num_inputs("./mem_layout.txt");               
        mem_layout = get_mem_layout("./mem_layout.txt", num_inputs);   
                                                    
        sizes = divide_data(num_inputs, DIV);                                  
                                          
        while(i < DIV){                                         
                // Write to file                                       
                bytes_wr = write(fd_w, mem_layout + start_addr, sizes[i]*sizeof(uint32_t));
                printf("start_adr: %d\n", start_addr);
                for(j = 0; j < 10; j++){     
                        printf("%X ", mem_layout[j + start_addr]);
                        //printf("addr =  %d + %d\n", start_addr, j);
                }                                                
                printf(" ...\n");                                                          
                usleep(100);                          
                //i += MAX_BUF_SIZE;                                           
                start_addr += sizes[i];                           
                i++;                                                 
        }                                                              
                                                                                           
        free(mem_layout);                             
        close(fd_w);                                                           
        pthread_exit(NULL);                                       
}

void * read_axis_fifo(void * arg){                                                         
        int fd_r, i, j;                               
        uint32_t * out_buff;                                                   
        uint32_t output_size;                                     
        ssize_t bytes_rd;                                            
                                                                       
        printf("Thread 2 (read fifo)\n");                                                  
                                                      
        fd_r = *(int*)arg;                                                     
        output_size = 61;                                         
        out_buff = malloc(output_size*sizeof(uint32_t));             
                                                                       
        //while(i < num_inputs){                                                           
        //while(running){                             
        sleep(1);                                                              
                                                                  
                bytes_rd = read(fd_r, out_buff, output_size*sizeof(uint32_t));
                if(bytes_rd > 0){                                      
                        printf("Receiving data!\n");                                       
                        for(j = 0; j < output_size; j++){
                                printf("(%X) ", out_buff[j]);                  
                        }                                         
                        printf("Bytes read: %d\n", bytes_rd);                 
                }                                                      
        //}                                                                                
        printf("\n");                                    
                                                             
        free(out_buff);                                           
        pthread_exit(NULL);                                                   
}

int main(){

	pthread_t th1, th2;
	int fd_w, fd_r;

	if((fd_w = open("/dev/axis_fifo_0x43c00000", O_WRONLY)) == -1){
		printf("[ERROR] Opening file: %s", strerror(errno));
		pthread_exit(NULL);
	}
	if((fd_r = open("/dev/axis_fifo_0x43c00000", O_RDONLY)) == -1){
		printf("[ERROR] Opening file: %s", strerror(errno));
		pthread_exit(NULL);
	}
	//Create threads
	pthread_create(&th1, NULL, write_axis_fifo, (void *) &fd_w);
	pthread_create(&th2, NULL, read_axis_fifo, (void *) &fd_r);

	//while(running){
	//	sleep(1);
	//}

	//printf("Bye bye ...\n");
	pthread_join(th1, NULL);
	pthread_join(th2, NULL);

	return 0;
}
