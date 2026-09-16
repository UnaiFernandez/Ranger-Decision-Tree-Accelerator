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

#define MAX_BUF_SIZE 208
#define NUM_INFERENCES 60

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
    num_inputs = data;

    //fscanf(fd_mem, "%X", &data);
    //num_labels = data;
    
    mem_layout = malloc(num_inputs * sizeof(uint32_t));
    
    while(!feof(fd_mem) && i < num_inputs){
        fscanf(fd_mem, "%X", &data);
        mem_layout[i] = data;
        i++;
    }

    num_labels = mem_layout[0];
    
    labels_base = num_inputs - num_labels;
    
    fclose(fd_mem);
    return 0;
}


void * write_axis_fifo(void * arg){                                    
    int fd_w, i, j;                                                        
    int start_addr = 0;                   
    ssize_t bytes_wr;                                       
    uint32_t chunk_size;                                              
    struct pollfd pfd;
    

    printf("[INFO] Thread 1 (write fifo)\n");          

    fd_w = *(int *)arg;

    pfd.fd = fd_w;
    pfd.events = POLLOUT;

    printf("[*] Sending data ...\n");
    while(start_addr < num_inputs){

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
    printf("\n");                                                          

    close(fd_w);                                                           
    pthread_exit(NULL);                                       
}

//void * read_axis_fifo(void * arg){                                                         
//    int fd_r, j;                               
//    uint32_t * out_buff;                                                   
//    uint32_t output_size;                                     
//    size_t total_bytes_to_read;
//    size_t total_bytes_read = 0;
//    struct pollfd pfd; // Estructura para el poll
//
//    printf("[INFO] Thread 2 (read fifo)\n");                                                  
//
//    fd_r = *(int*)arg;                                                     
//    output_size = num_labels + 1;                                         
//    total_bytes_to_read = output_size * sizeof(uint32_t);
//    out_buff = malloc(total_bytes_to_read);             
//
//    // Configuración del poll
//    pfd.fd = fd_r;
//    pfd.events = POLLIN; // Queremos saber cuándo hay datos listos para ser leídos
//
//    printf("[*] Esperando a que la FPGA tenga datos disponibles...\n");
//
//    // Bucle para asegurar que leemos exactamente todo el paquete completo
//    while (total_bytes_read < total_bytes_to_read) {
//        
//        // Espera de hasta 5000 milisegundos (5 segundos) a que llegue el evento POLLIN
//        int ret = poll(&pfd, 1, 5000); 
//        
//        if (ret < 0) {
//            printf("[ERROR] Error en el poll de lectura: %s\n", strerror(errno));
//            break;
//        } else if (ret == 0) {
//            printf("[WARNING] Timeout: La FPGA no ha devuelto datos en 5 segundos.\n");
//            break;
//        }
//
//        // Si el evento recibido es POLLIN, leemos de forma segura la ráfaga disponible
//        if (pfd.revents & POLLIN) {
//            size_t bytes_restantes = total_bytes_to_read - total_bytes_read;
//            ssize_t bytes_rd = read(fd_r, (char*)out_buff + total_bytes_read, bytes_restantes);
//            
//            if (bytes_rd < 0) {
//                printf("[ERROR] Error leyendo de la FIFO: %s\n", strerror(errno));
//                break;
//            } else if (bytes_rd == 0) {
//                printf("[WARNING] La FIFO se cerró inesperadamente.\n");
//                break; 
//            }
//
//            total_bytes_read += bytes_rd;
//        }
//    }
//
//    // Comprobamos si logramos absorber con éxito todo el bloque de datos esperado
//    if(total_bytes_read == total_bytes_to_read){                                      
//        printf("[*] Receiving data: ");                                       
//        for(j = 0; j < 10; j++){
//            printf("(%X) ", out_buff[j]);                  
//        }                 
//        printf("... ");
//        printf("(%X) -- ", out_buff[output_size-1]);
//        printf("Bytes read: %zu\n", total_bytes_read);                 
//    } else {
//        printf("[ERROR] Lectura incompleta. Se leyeron %zu de %zu bytes esperados.\n", 
//               total_bytes_read, total_bytes_to_read);
//    }                                                      
//                                                                                    
//    float avg_c_time = (out_buff[num_labels]/(float)num_labels)*10.0;
//    float samp_p_sec = 1.0/(avg_c_time / 1000000000.0);
//    printf("--------------------------------------\n");
//    printf("[*] Total cycles: %d\n", out_buff[num_labels]);
//    printf("[*] Average inference time: %0.2f ns\n", avg_c_time);
//    printf("[*] Samples per second: %0.2f samp/s\n", samp_p_sec);
//
//    int c = 0;
//
//    for(int j = 0; j < num_labels; j++){
//        if(out_buff[j] == mem_layout[labels_base + j]){
//            c++;
//        }
//    }
//    float acc = (c * 100.0)/(float)num_labels;
//    printf("[*] Accuracy: %0.2f %% (%d/%d)\n", acc, c, num_labels);
//
//    export_results_to_csv("resultado_inferencia.csv", out_buff, output_size, &mem_layout[labels_base], num_labels);
//    free(out_buff);                                           
//    pthread_exit(NULL);                                                   
//}


void * read_axis_fifo(void * arg){                                                         
    int fd_r, i, j;                               
    uint32_t * out_buff;                                                   
    uint32_t output_size;                                     
    ssize_t bytes_rd;                                            

    //usleep(3000);
    printf("[INFO] Thread 2 (read fifo)\n");                                                  

    fd_r = *(int*)arg;                                                     
    output_size = num_labels + 1;                                         
    out_buff = malloc(output_size*sizeof(uint32_t));             

    //printf("Output size: %d\n", output_size);
    //while(i < num_inputs){                                                           
    //while(running){                             

    bytes_rd = read(fd_r, out_buff, output_size*sizeof(uint32_t));
    if(bytes_rd == (ssize_t)(output_size * sizeof(uint32_t))){                                      
        printf("[*] Receiving data: ");                                       
        for(j = 0; j < 10; j++){
            printf("(%X) ", out_buff[j]);                  
        }                 
        printf("... ");
        printf("(%X) -- ", out_buff[output_size-1]);
        printf("Bytes read: %d\n", bytes_rd);                 
    }                                                      
    //}                                                                                
    float avg_c_time = (out_buff[num_labels]/(float)num_labels)*10.0;
    float samp_p_sec = 1.0/(avg_c_time / 1000000000.0);
    printf("--------------------------------------\n");
    printf("[*] Total cycles: %d\n", out_buff[num_labels]);
    printf("[*] Average inference time: %0.2f ns\n", avg_c_time);
    printf("[*] Samples per second: %0.2f samp/s\n", samp_p_sec);

    int c = 0;

    for(int j = 0; j < num_labels; j++){
        if(out_buff[j] == mem_layout[labels_base + j]){
            c++;
        }
    }
    float acc = (c * 100.0)/(float)num_labels;
    printf("[*] Accuracy: %0.2f \% (%d/%d)\n", acc, c, num_labels);

    export_results_to_csv("resultado_inferencia.csv", out_buff, output_size, &mem_layout[labels_base], num_labels);
    free(out_buff);                                           
    pthread_exit(NULL);                                                   
}

int main(int argc, char ** argv){

    pthread_t th1, th2;
    int fd_w, fd_r;

    //printf("    ___   _  __ _________       __            __ \n");
    //printf("   /   | | |/ //  _/ ___/      / /____  _____/ /_\n");
    //printf("  / /| | |   / / / \\__ \\______/ __/ _ \\/ ___/ __/\n");
    //printf(" / ___ |/   |_/ / ___/ /_____/ /_/  __(__  ) /_  \n");
    //printf("/_/  |_/_/|_/___//____/      \\__/\\___/____/\\__/  \n\n");

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

    printf("[INFO] File: %s\n", argv[1]);

    //get_mem_layout("./mem_layout.txt");   
    if (get_mem_layout(argv[1]) != 0){
        close(fd_w);
        close(fd_r);
        return EXIT_FAILURE;
    } 

    usleep(500);

    //Create threads
    pthread_create(&th1, NULL, write_axis_fifo, (void *) &fd_w);
    pthread_create(&th2, NULL, read_axis_fifo, (void *) &fd_r);

    //while(running){
    //	sleep(1);
    //}

    //printf("Bye bye ...\n");
    pthread_join(th1, NULL);
    pthread_join(th2, NULL);

    free(mem_layout);                             
    return 0;
}
