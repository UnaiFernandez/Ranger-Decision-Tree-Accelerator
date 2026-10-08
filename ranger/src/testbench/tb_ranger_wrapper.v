`timescale 1 ns / 1 ps

module tb_ranger_wrapper();

  // ==========================================
  // SEÑALES ORIGINALES DEL TESTBENCH
  // ==========================================
  reg btn0;
  reg btn1;
  reg btn2;
  reg sysclk;
  wire led0;
  wire led1;
  wire led2;
  wire led3;

  // ==========================================
  // INSTANCIACIÓN DEL DUT (Limpio y sin pines AXI externos)
  // ==========================================
  design_1_wrapper dut (
    .btn0(btn0),
    .btn1(btn1),
    .btn2(btn2),
    .led0(led0),
    .led1(led1),
    .led2(led2),
    .led3(led3),
    .sysclk(sysclk)
  );

  // Generador de Reloj del sistema (62.5 MHz)
  initial sysclk = 0;
  always #8 sysclk = ~sysclk;

  // ==========================================
  // SECUENCIA PRINCIPAL DE ESTÍMULOS
  // ==========================================
  initial begin
    btn0 = 0; btn1 = 0; btn2 = 0;
    
    $display("Iniciando simulación del sistema...");
    #200;

    // Reset del sistema (Ambos módulos despiertan con sus polaridades correspondientes)
    btn0 = 1;
    #200;
    btn0 = 0; 
    #1000; // Margen de tiempo para estabilización tras el reset
    
    // Pulso de inicialización original de tu lógica
    btn1 = 1;
    #100;
    btn1 = 0;
    
    // =========================================================================
    // NOTA: El AXI Traffic Generator interno se encargará de forma automática
    // de inyectar tus 2202 datos y de disparar el registro TLR (0x14).
    // Tu testbench ahora solo debe esperar a ver la ejecución en tu módulo.
    // =========================================================================

    // Dejar correr la simulación un tiempo amplio para ver el procesamiento del Stream
    #400000;

    $display("Simulación finalizada.");
    $finish; 
  end

  // Monitorización por consola
  initial begin
    $monitor("Tiempo: %t | BTNs: %b%b%b | LEDs: %b%b%b%b", 
              $time, btn2, btn1, btn0, led3, led2, led1, led0);
  end

endmodule

