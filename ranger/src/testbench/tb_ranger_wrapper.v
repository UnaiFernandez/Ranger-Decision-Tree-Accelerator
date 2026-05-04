`timescale 1 ns / 1 ps

module tb_design_1_wrapper();

  reg btn0;
  reg btn1;
  reg btn2;
  reg sysclk;
  wire led0;
  wire led1;
  wire led2;
  wire led3;

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

  initial sysclk = 0;
  always #10 sysclk = ~sysclk;

  initial begin
    btn0 = 0; btn1 = 0; btn2 = 0;
    
    $display("Iniciando simulación...");
    #200;

    //Reset
    btn0 = 1;
    #200;
    btn0 = 0;
    #50;
    // Init
    btn1 = 1;
    #100;
    btn1 = 0;
    #120000;

    $display("Simulación finalizada.");
    $finish; // Detiene el simulador
  end

  // Opcional: Monitor de señales en consola
  initial begin
    $monitor("Tiempo: %t | BTNs: %b%b%b | LEDs: %b%b%b%b", 
              $time, btn2, btn1, btn0, led3, led2, led1, led0);
  end

endmodule
