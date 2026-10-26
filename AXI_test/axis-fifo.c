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

#define MAX_BUF_SIZE 500
#define NUM_INFERENCES 60
#define NUM_SAMPLES_POW 2000
#define REPS 1

#define DIV 2
static volatile int running = 1;

uint32_t * mem_layout = NULL;                                         
uint32_t num_inputs = 0;                        
uint32_t num_labels = 0;                        
uint32_t num_features = 0;
uint32_t conf_size = 0;
uint32_t labels_base = 0;
uint32_t divisor = 1;

//clock_t start, stop;

struct timespec start;
struct timespec stop;

static inline uint64_t timespec_diff_ns(struct timespec *start, struct timespec *end)
{
    struct timespec result;
    if ((end->tv_nsec - start->tv_nsec) < 0) {
        result.tv_sec = end->tv_sec - start->tv_sec - 1;
        result.tv_nsec = end->tv_nsec - start->tv_nsec + 1000000000L;
    } else {
        result.tv_sec = end->tv_sec - start->tv_sec;
        result.tv_nsec = end->tv_nsec - start->tv_nsec;
    }

    return (result.tv_sec * 1000000000L) + result.tv_nsec;
}



//static int ranger_exec = 0;
//static pthread_mutex_t __mutex_shared_variable = (pthread_mutex_t) PTHREAD_MUTEX_INITIALIZER;

struct power_t{
        struct timespec timestamp;
        int raw;
        float current;
        float power;
        int r_exec;
};

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

int export_results_to_csv(const char *filename, uint32_t *out_buff, uint32_t num_labels) {
    FILE *csv_file = fopen(filename, "w");
    if (csv_file == NULL) {
        fprintf(stderr, "[ERROR] No se pudo crear el archivo CSV: %s\n", strerror(errno));
        return -1;
    }

    fprintf(csv_file, "Indice,Valor Obtenido (HEX)\n");

    for (uint32_t j = 0; j < num_labels; j++) {
        uint32_t obtenido = out_buff[j];

        fprintf(csv_file, "%u,0x%X\n", j, obtenido);

    }


    fclose(csv_file);
    printf("[INFO] Resultados exportados exitosamente a '%s'\n", filename);
    return 0;
}

int export_results_to_csv_float(const char *filename, struct power_t *out_buff, uint32_t num_labels) {
    FILE *csv_file = fopen(filename, "w");
    if (csv_file == NULL) {
        fprintf(stderr, "[ERROR] No se pudo crear el archivo CSV: %s\n", strerror(errno));
        return -1;
    }

    fprintf(csv_file, "Timestamp,RAW_XADC,Corriente_A,Potencia_W,Exec\n");

    for (uint32_t j = 0; j < num_labels; j++) {
        struct power_t obtenido = out_buff[j];
        int r_exec = out_buff[j].r_exec;
        uint64_t timestamp = (obtenido.timestamp.tv_sec * 1000000000ULL) + obtenido.timestamp.tv_nsec;

        fprintf(csv_file, "%llu,%08X,%0.2f,%0.2f,%d\n", (unsigned long long)timestamp, obtenido.raw, obtenido.current, obtenido.power, obtenido.r_exec);

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
   
    labels_base = num_inputs - num_labels;
    
    fclose(fd_mem);
    return 0;
}

void * measure_power (void * arg){
   
    int fd_pow;
    char buffer[16];
    struct power_t * out_power_buff;
    ssize_t bt_read;
    struct power_t p_meas;
    int idx = 0;

   

    fd_pow = *(int *)arg;

    out_power_buff = (struct power_t*)malloc(NUM_SAMPLES_POW*sizeof(struct power_t));


    for(int i = 0; i < NUM_SAMPLES_POW; i++){
    
        lseek(fd_pow, 0, SEEK_SET); //colocar al principio el puntero
    
        bt_read = read(fd_pow, buffer, sizeof(buffer));
        if(bt_read <= 0){
            printf("\n[ERROR] Fallo en la lectura de la muestra %d\n", i);
            close(fd_pow);
            pthread_exit(NULL);
        }

        clock_gettime(CLOCK_MONOTONIC, &p_meas.timestamp);

        p_meas.raw = atoi(buffer);

        p_meas.current = ((((float)p_meas.raw * 244.0) / 3900.0) - 0.8 ) / 52.0;

        if(p_meas.current < 0.0){
            p_meas.current = 0.0;
        }

        p_meas.power = 5.0 * p_meas.current;

        p_meas.r_exec = 0;

        //printf("%d | %0.2f | %0.2f\n", p_meas.raw, p_meas.current, p_meas.power);

        out_power_buff[idx] = p_meas;


        usleep(2000);
        idx++;
    }

    //for(int i = 0; i < 30; i++){
    //    printf("%0.2f\n", out_power_buff[i].power);
    //}
  
    export_results_to_csv_float("power_results.csv", out_power_buff, NUM_SAMPLES_POW);
    close(fd_pow); 
    free(out_power_buff);
    pthread_exit(NULL);
}

void * write_axis_fifo(void * arg){                                    
    int fd_w;                                                        
    int start_addr = conf_size;                   
    ssize_t bytes_wr;                                       
    uint32_t chunk_size;                                              
    struct pollfd pfd;

    fd_w = *(int *)arg;

    pfd.fd = fd_w;
    pfd.events = POLLOUT;

    printf(">> Inference data\n");

    //start = clock();
    clock_gettime(CLOCK_MONOTONIC, &start);
    for(int i = 0; i < REPS; i++){
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
                start_addr += chunk_size;  
            }
        } 
    }

    close(fd_w);                                                           
    pthread_exit(NULL);                                       
}

int send_config(void * arg){                                    
    int fd_w;                                                        
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
            usleep(100);                          
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


    for(int k = 0; k < REPS; k++){
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
        printf("Read -> %d\n", k);

    //stop = clock();
    clock_gettime(CLOCK_MONOTONIC, &stop);

    }                                                      
    //}                                                                                
    float avg_c_time = (out_buff[num_labels]/(float)num_labels)*10.0;
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

    //ranger_exec = 0;
    //stop = clock();

    export_results_to_csv("resultado_inferencia.csv", out_buff, num_labels);
    free(out_buff);                                           
    pthread_exit(NULL);                                                   
}

int main(int argc, char ** argv){

    pthread_t th1, th2, th_pow;
    int fd_w, fd_r, fd_pow;
    uint64_t total_time;

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
    
    if((fd_pow = open("/sys/bus/iio/devices/iio:device1/in_voltage8_raw", O_RDONLY)) == -1){
        printf("[ERROR] Opening file: %s", strerror(errno));
        pthread_exit(NULL);
    }
    printf(">> Opened file: %s\n", argv[1]);


    pthread_create(&th_pow, NULL, measure_power, (void *) &fd_pow);

    sleep(2);

    //get_mem_layout("./mem_layout.txt");   
    if (get_mem_layout(argv[1]) != 0){
        close(fd_w);
        close(fd_r);
        return EXIT_FAILURE;
    } 
    

    usleep(500);

    send_config((void *) &fd_w);


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
    pthread_join(th_pow, NULL);


    total_time = timespec_diff_ns(&start, &stop);
    

    //double total_time = (double)(stop - start)/CLOCKS_PER_SEC;

    printf("Total ns: %ld\n", total_time);


    free(mem_layout);                             
    return 0;
}
