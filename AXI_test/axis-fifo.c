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

int main(){
    int fd_w, fd_r, i;
    uint32_t num_inputs;
    uint32_t * mem_layout;
	uint32_t * out_buff;
	ssize_t bytes_rd;
	ssize_t bytes_wr;

	num_inputs = get_num_inputs("./mem_layout.txt");
	mem_layout = get_mem_layout("./mem_layout.txt", num_inputs);

	out_buff = malloc(num_inputs*sizeof(uint32_t));

	if((fd_w = open("./file", O_WRONLY)) == -1){
		printf("[ERROR] Opening file: %s", strerror(errno));
		pthread_exit(NULL);
	}
	if((fd_r = open("./file", O_RDONLY)) == -1){
		printf("[ERROR] Opening file: %s", strerror(errno));
		pthread_exit(NULL);
	}

	// Write to file
	bytes_wr = write(fd_w, mem_layout, num_inputs*sizeof(uint32_t));
	for(i = 0; i < num_inputs; i++){
		printf("%X ", mem_layout[i]);
	}
	printf("\n");

	bytes_rd = read(fd_r, out_buff, num_inputs * sizeof(uint32_t));
	for(i = 0; i < num_inputs; i++){
		printf("%X ", out_buff[i]);
	}
	printf("\n");

	free(out_buff);
	free(mem_layout);
	close(fd_w);
	close(fd_r);
	return 0;
}
