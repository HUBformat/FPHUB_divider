// Wrapper para el módulo de división en formato HUB, adaptado a la interfaz de FPnew.
module fpnew_hub_divider_wrapper #(
  parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::FP16,
  parameter int unsigned WIDTH = fpnew_pkg::fp_width(FpFormat),
  parameter int unsigned M = fpnew_pkg::man_bits(FpFormat),
  parameter int unsigned E = fpnew_pkg::exp_bits(FpFormat)
)(
  // Interfaz de entrada de FPnew
  input  logic clk_i,
  input  logic rst_ni,
  input  logic [2:0][WIDTH-1:0] operands_i,
  input  fpnew_pkg::operation_e op_i,
  input  logic op_mod_i,
  input  logic in_valid_i,
  output logic in_ready_o,
  input  logic flush_i,
  // Interfaz de salida de FPnew
  output logic [WIDTH-1:0] result_o,
  output fpnew_pkg::status_t status_o,
  output logic out_valid_o,
  input  logic out_ready_i,
  output logic busy_o
);

  // Señales internas para tu módulo divider
  logic [E+M:0] hub_x_input;
  logic [E+M:0] hub_d_input;
  logic [E+M:0] hub_res_output;
  logic hub_start_signal, hub_finish_signal, hub_computing_signal, hub_special_case_detected_signal;

  FPHUB_divider #(
    .M(M),
    .E(E),
    .N(32)
  ) i_hub_divider (
    .clk(clk_i),        
    .rst_l(rst_ni),     
    .start(hub_start_signal),    
    .x(hub_x_input),          
    .d(hub_d_input),          
    .res(hub_res_output),      
    .finish(hub_finish_signal),       
    .computing(hub_computing_signal),
    .special_case_detected(hub_special_case_detected_signal)
  );

  // Mapeo de los operandos del FPnew al formato de HUB
  // El FPnew usa op[0] y op[1] para la división
  assign hub_x_input = operands_i[0];
  assign hub_d_input = operands_i[1];
  
  // -------------------------------------------
  // Lógica de Handshake
  // -------------------------------------------


  // in_ready_o está activo cuando la FPU está lista para recibir una nueva operación de división
  assign in_ready_o = ~hub_computing_signal;
  
  // Iniciación de la operación válida
  // Pulso de inicio: ocurre en el ciclo donde la entrada es válida Y el módulo está listo
  assign hub_start_signal = op_i == fpnew_pkg::DIV ? in_valid_i && in_ready_o : 1'b0;

  // out_valid_o se activa cuando la entrada es válida y el op_i es de división
  assign out_valid_o = hub_finish_signal;

  // El resultado de la división se asigna directamente a la salida
  assign result_o = hub_res_output;

  // Usamos la señal computing del divisor como la señal busy_o del fpnew
  assign busy_o = hub_computing_signal;

  // Lógica de flags de estado de FPnew (status_t)
//  // Basado en el formato de HUB
//  logic is_inf_output;
//  logic is_zero_output;
//
//  // Comprueba si la salida es Infinito (todos los bits del exponente y la mantisa son 1)
//  assign is_inf_output = (hub_res_output[E+M-1:0] == {(E+M){1'b1}});
//
//  // Comprueba si la salida es Cero (todos los bits del exponente y la mantisa son 0)
//  assign is_zero_output = (hub_res_output[E+M-1:0] == {(E+M){1'b0}});
//
//  // Asignación de flags de estado (simplificada)
//  assign status_o.NV = 1'b0; 
//  assign status_o.DZ = 1'b0; 
//  assign status_o.OF = is_inf_output;
//  assign status_o.UF = is_zero_output;
//  assign status_o.NX = 1'b0; // Pendiente de implementar

endmodule