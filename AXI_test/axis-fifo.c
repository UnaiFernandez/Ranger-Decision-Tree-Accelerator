#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>


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

	for(i = 0; i < num_inputs; i++){
		printf("%X ", mem_layout[i]);
	}
	printf("\n");

	fclose(fd_mem);

	return mem_layout;
}


void * write_axis_fifo(void * arg){
	uint32_t * mem_layout;
	uint32_t num_inputs;
	int fd_w, i;
	ssize_t bytes_wr;

	printf("Thread 1 (write fifo)\n");

	fd_w = *(int *)arg;
	num_inputs = get_num_inputs("./mem_layout.txt");
	mem_layout = get_mem_layout("./mem_layout.txt", num_inputs);

	// Write to file
	bytes_wr = write(fd_w, mem_layout, num_inputs*sizeof(uint32_t));
	for(i = 0; i < num_inputs; i++){
		printf("%X ", mem_layout[i]);
	}
	printf("\n");

	free(mem_layout);
	close(fd_w);
	pthread_exit(NULL);
}

void * read_axis_fifo(void * arg){
	int fd_r, i, j;
	uint32_t * out_buff;
	uint32_t num_inputs;
	ssize_t bytes_rd;

	printf("Thread 2 (read fifo)\n");

	fd_r = *(int*)arg;
	num_inputs = get_num_inputs("./mem_layout.txt");
	out_buff = malloc(num_inputs*sizeof(uint32_t));

	//// Write to file
	//bytes_rd = write(fd_r, out_buff, num_inputs*sizeof(uint32_t));
	//for(i = 0; i < num_inputs; i++){
	//	printf("%X ", out_buff[i]);
	//}
	//printf("\n");
	while(i < num_inputs){
		bytes_rd = read(fd_r, out_buff, num_inputs*sizeof(uint32_t));
		if(bytes_rd > 0){
			for(j = 0; j < num_inputs; j++){
				printf("(%X) ", out_buff[j]);
			}
			i+=num_inputs;
		}
	} 
	printf("\n");

	free(out_buff);
	pthread_exit(NULL);
}

int main(){

	pthread_t th1, th2;
	int fd_w, fd_r;

	//if((fd_w = open("/dev/axis_fifo_0x43c00000", O_WRONLY)) == -1){
	if((fd_w = open("./file", O_WRONLY)) == -1){
		printf("[ERROR] Opening file: %s", strerror(errno));
		pthread_exit(NULL);
	}
	//if((fd_r = open("/dev/axis_fifo_0x43c00000", O_RDONLY)) == -1){
	if((fd_r = open("./file2", O_RDONLY)) == -1){
		printf("[ERROR] Opening file: %s", strerror(errno));
		pthread_exit(NULL);
	}
	//Create threads
	pthread_create(&th1, NULL, write_axis_fifo, (void *) &fd_w);
	pthread_create(&th2, NULL, read_axis_fifo, (void *) &fd_r);

	pthread_join(th1, NULL);
	pthread_join(th2, NULL);

	return 0;
}
