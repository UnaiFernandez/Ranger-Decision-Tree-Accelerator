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

#define MAX_BUF_SIZE 256
#define NUM_INFERENCES 60

#define DIV 2
static volatile int running = 1;

uint32_t * mem_layout = NULL;                                         
uint32_t num_inputs = 0;                        
uint32_t num_labels = 0;                        
uint32_t num_features = 0;
uint32_t conf_size = 0;
uint32_t labels_base = 0;
uint32_t divisor = 1;

clock_t start, stop;

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

int export_results_to_csv(const char *filename, uint32_t *out_buff, uint32_t output_size, uint32_t *expected_labels, uint32_t num_labels) {
    FILE *csv_file = fopen(filename, "w");
    if (csv_file == NULL) {
        fprintf(stderr, "[ERROR] No se pudo crear el archivo CSV: %s\n", strerror(errno));
        return -1;
    }

    // 1. Escribir metadatos generales al inicio del CSV
    uint32_t total_cycles = out_buff[num_labels];
    float avg_c_time = (total_cycles / (float)num_labels) * 10.0f;
    
    //fprintf(csv_file, "# Resumen de Inferencia\n");
    //fprintf(csv_file, "Total Ciclos,%u\n", total_cycles);
    //fprintf(csv_file, "Tiempo Promedio (ns),%.2f\n\n", avg_c_time);

    // 2. Escribir las cabeceras de la tabla de datos
    //fprintf(csv_file, "Indice,Valor Obtenido (HEX),Valor Esperado (HEX),Resultado\n");
    fprintf(csv_file, "Indice,Valor Obtenido (HEX)\n");

    // 3. Escribir cada inferencia fila por fila
    int correctas = 0;
    for (uint32_t j = 0; j < num_labels; j++) {
        uint32_t obtenido = out_buff[j];

        fprintf(csv_file, "%u,0x%X\n", j, obtenido);
    }


    fclose(csv_file);
    printf("[INFO] Resultados exportados exitosamente a '%s'\n", filename);
    return 0;
}


int get_mem_layout(char * filename){
    FILE * fd_mem;
    uint32_t data, i = 0;


    if((fd_mem = fopen(filename, "r")) == NULL){
        printf("[ERROR] Opening mem layout file: %s", strerror(errno));
        return -1;
    }

    if(fscanf(fd_mem, "%X", &data) != 1){
        printf("[ERROR] Failed to read fd_mem\n");
        fclose(fd_mem);
        return -1;
    }

    num_features = data >> 24;
    num_inputs = data & 0xFFFFFF;

    //fscanf(fd_mem, "%X", &data);
    //num_labels = data;
    
    mem_layout = malloc(num_inputs * sizeof(uint32_t));
    
    while(!feof(fd_mem) && i < num_inputs){
        fscanf(fd_mem, "%X", &data);
        mem_layout[i] = data;
        i++;
    }

    num_labels = mem_layout[0];


    conf_size = num_inputs - num_labels - (num_features * num_labels);
    //printf("Num imputs: %d\nNum features: %d\nConf_size: %d\n", num_inputs, num_features, conf_size);
   
    labels_base = num_inputs - num_labels;
    
    fclose(fd_mem);
    return 0;
}


void * write_axis_fifo(void * arg){                                    
    int fd_w, i, j;                                                        
    int start_addr = conf_size;                   
    ssize_t bytes_wr;                                       
    uint32_t chunk_size;                                              
    struct pollfd pfd;
    

    //printf("[INFO] Thread 1 (write fifo)\n");          

    fd_w = *(int *)arg;

    pfd.fd = fd_w;
    pfd.events = POLLOUT;

    printf(">> Inference data\n");
    printf("%08X\n", mem_layout[conf_size]);
    printf("%08X\n", mem_layout[conf_size - 1]);

    start = clock();
    while(start_addr < (num_inputs - num_labels)){

        int ret = poll(&pfd, 1, 2000); //esperar FIFO 1000ms

        if(ret < 0){
            printf("[ERROR] Poll error: %s\n", strerror(errno));
            break;
        }else if(ret == 0){
            printf("[WARNING] Timeout: La FPGA no está liberando espacio en la FIFO\n");
            continue;
        }

        if(pfd.revents & POLLOUT){
            if((num_inputs - start_addr) > MAX_BUF_SIZE){
                chunk_size = MAX_BUF_SIZE;
            }else{
                chunk_size = num_inputs - start_addr;
            }

            // Write to file                                       
            bytes_wr = write(fd_w, mem_layout + start_addr, chunk_size*sizeof(uint32_t));

            if(bytes_wr < 0){
                printf("[ERROR] Write failed: %s\n", strerror(errno));
                break;
            }
            //printf("start_adr: %d\n", start_addr);
            //printf("%8X [%d]\n", mem_layout[start_addr], start_addr);
            //for(j = 0; j < 10; j++){     
                //printf("%X ", mem_layout[j + start_addr]);
                //printf(".");
                //printf("addr =  %d + %d\n", start_addr, j);
            //}                                                
            //usleep(100);                          
            //i += MAX_BUF_SIZE;                                           
            start_addr += chunk_size;  
        }
    }                                                              
    //printf("\n");                                                          

    close(fd_w);                                                           
    pthread_exit(NULL);                                       
}

int send_config(void * arg){                                    
    int fd_w, i, j;                                                        
    int start_addr = 0;                   
    ssize_t bytes_wr;                                       
    uint32_t chunk_size;                                              
    struct pollfd pfd;
    

    fd_w = *(int *)arg;

    pfd.fd = fd_w;
    pfd.events = POLLOUT;

    printf(">> Configuration ");
    while(start_addr < conf_size){

        int ret = poll(&pfd, 1, 2000); //esperar FIFO 2000ms

        if(ret < 0){
            printf("\n[ERROR] Poll error: %s\n", strerror(errno));
            break;
        }else if(ret == 0){
            printf("\n[WARNING] Timeout: La FPGA no está liberando espacio en la FIFO\n");
            continue;
        }

        if(pfd.revents & POLLOUT){
            if((conf_size - start_addr) > MAX_BUF_SIZE){
                chunk_size = MAX_BUF_SIZE;
            }else{
                chunk_size = conf_size - start_addr;
            }

            // Write to file                                       
            bytes_wr = write(fd_w, mem_layout + start_addr, chunk_size*sizeof(uint32_t));

            if(bytes_wr < 0){
                printf("\n[ERROR] Write failed: %s\n", strerror(errno));
                break;
            }
            //printf("start_adr: %d\n", start_addr);
            //printf("%8X [%d]\n", mem_layout[start_addr], start_addr);
            //for(j = 0; j < 10; j++){     
                //printf("%X ", mem_layout[j + start_addr]);
                //printf(".");
                //printf("addr =  %d + %d\n", start_addr, j);
            //}                                                
            usleep(100);                          
            //i += MAX_BUF_SIZE;                                           
            start_addr += chunk_size;  
        }
    }
    printf("[DONE]\n");                                                          

    return 0;
}

void * read_axis_fifo(void * arg){                                                         
    int fd_r, i, j;                               
    uint32_t * out_buff;                                                   
    uint32_t output_size;                                     
    ssize_t bytes_rd; 

    //usleep(3000);
    //sleep(1);
    //printf("[INFO] Thread 2 (read fifo)\n");                                                  

    fd_r = *(int*)arg;                                                     
    output_size = num_labels + 1;                                         
    out_buff = malloc(output_size*sizeof(uint32_t));             

    //printf("Output size: %d\n", output_size);
    //while(i < num_inputs){                                                           
    //while(running){                             

    i = 0;
    bytes_rd = read(fd_r, out_buff, output_size*sizeof(uint32_t));
    if(bytes_rd == (ssize_t)(output_size * sizeof(uint32_t))){                                      
        //printf(">> Received %d Bytes\n\n", bytes_rd);                                       
        for(j = 0; j < 40; j++){
            i++;
          //  printf("%04X ", out_buff[j]);                  
            if(i == 10){
            //    printf("\n");
                i = 0;
            }
        }                 
        //printf("\n");
    }                                                      

    stop = clock();
    //}                                                                                
    float avg_c_time = (out_buff[num_labels]/(float)num_labels)*8.0;
    float samp_p_sec = 1.0/(avg_c_time / 1000000000.0);
    printf("-------------------------------------------------\n");
    printf("   - Total cycles: %d\n", out_buff[num_labels]);
    printf("   - Average inference time: %0.2f ns\n", avg_c_time);
    printf("   - Samples per second: %0.2f samp/s\n", samp_p_sec);

    int c = 0;

    for(int j = 0; j < num_labels; j++){
        if(out_buff[j] == mem_layout[labels_base + j]){
            c++;
        }
    }
    float acc = (c * 100.0)/(float)num_labels;
    printf("   - Accuracy: %0.2f \% (%d/%d)\n", acc, c, num_labels);

    export_results_to_csv("resultado_inferencia.csv", out_buff, output_size, &mem_layout[labels_base], num_labels);
    free(out_buff);                                           
    pthread_exit(NULL);                                                   
}

int main(int argc, char ** argv){

    pthread_t th1, th2;
    int fd_w, fd_r;

    printf("    ____  ___    _   __________________        __            __   \n"); 
    printf("   / __ \\/   |  / | / / ____/ ____/ __ \\      / /____  _____/ /_\n");
    printf("  / /_/ / /| | /  |/ / / __/ __/ / /_/ /_____/ __/ _ \\/ ___/ __/\n");
    printf(" / _, _/ ___ |/ /|  / /_/ / /___/ _, _/_____/ /_/  __(__  ) /_  \n");
    printf("/_/ |_/_/  |_/_/ |_/\\____/_____/_/ |_|      \\__/\\___/____/\\__/  \n\n\n");
                                                                

    if((fd_w = open("/dev/axis_fifo_0x43c00000", O_WRONLY)) == -1){
        printf("[ERROR] Opening file: %s", strerror(errno));
        pthread_exit(NULL);
    }
    if((fd_r = open("/dev/axis_fifo_0x43c00000", O_RDONLY)) == -1){
        printf("[ERROR] Opening file: %s", strerror(errno));
        pthread_exit(NULL);
    }

    printf(">> Opened file: %s\n", argv[1]);

    //get_mem_layout("./mem_layout.txt");   
    if (get_mem_layout(argv[1]) != 0){
        close(fd_w);
        close(fd_r);
        return EXIT_FAILURE;
    } 

    usleep(500);

    send_config((void *) &fd_w);

    //sleep(4);

    //clock_t start = clock();
    //Create threads
    pthread_create(&th1, NULL, write_axis_fifo, (void *) &fd_w);
    pthread_create(&th2, NULL, read_axis_fifo, (void *) &fd_r);
    
       //while(running){
    //	sleep(1);
    //}

    //printf("Bye bye ...\n");
    pthread_join(th1, NULL);
    pthread_join(th2, NULL);


    double total_time = (double)(stop - start)/CLOCKS_PER_SEC;

    printf("Total segundos: %f\n", total_time);


    free(mem_layout);                             
    return 0;
}
