//`timescale 1ns / 1ps

module special_cases_detector #(
    parameter int M = 23,                                       // Mantissa size
    parameter int E = 8,                                        // Exponent size
    parameter int special_case = 7                              // Number of special cases (including no special case)
)(              
    input logic [E+M:0] X,                                      // Entrada X
    input logic [E+M:0] Y,                                      // Entrada Y
    output logic [$clog2(special_case)-1:0] X_special_case,       // Indicador del caso especial de X (0 si no es especial)
    output logic [$clog2(special_case)-1:0] Y_special_case        // Indicador del caso especial de Y (0 si no es especial)
    );

/*-----------------------------------------------
Definición de casos especiales:
-----------------------------------------------*/
localparam logic [$clog2(special_case):0] 
        CASE_NONE = 0,       // Ningún caso especial
        CASE_INF_P = 1,      // +inf (0 11111111 11111111111111111111111)
        CASE_INF_N = 2,      // -inf (1 11111111 11111111111111111111111)
        CASE_ZERO_P = 3,     // +0   (0 00000000 00000000000000000000000)
        CASE_ZERO_N = 4,     // -0   (1 00000000 00000000000000000000000)
        CASE_ONE_P = 5,      // +1   (0 10000000 00000000000000000000000)
        CASE_ONE_N = 6;      // -1   (1 10000000 00000000000000000000000)

always_comb begin
    // Inicialmente, asumimos que no es caso especial
    X_special_case = 0;
    /*--------------------------------------------------------------------------------------------------
        Identificación de casos de infinito:
        Como en ambos casos de infitio los bits del exponente y de la mantisa son unos, se realiza esta
        comprobación primeramente. Si se cumple, se pasa a analizar el signo.
    ----------------------------------------------------------------------------------------------------*/
    if (X[E+M-1:0] == {E+M{1'b1}}) begin
        // Si el signo es 0, +inf (código 1); si es 1, -inf (código 2)
        X_special_case = (X[E+M]) ? CASE_INF_N : CASE_INF_P;
    end 
    /*--------------------------------------------------------------------------------------------------
        Identificación de casos de cero y uno:
        Tal y como se puede observar más arriba en el código, los casos de cero y uno tienen en común
        todos los bits excepto los dos más significativos. Siendo el MSB el bit de signo y el segundo
        bit más significativo el MSB del exponente. Esto de aprovecha para identificar estos casos de
        manera más eficiente.
    ----------------------------------------------------------------------------------------------------*/
    else if (X[E+M-2:0] == {E+M-1{1'b0}}) begin
        // Si el MSB del exponente es 1, es un caso especial de +1/-1. En caso contrario, +0/-0
        if (X[E+M-1]) begin
            // Si el signo es 0, +1 (código 5); si es 1, -1 (código 6)
            X_special_case = (X[E+M]) ? CASE_ONE_N : CASE_ONE_P;
        end
        else begin
            // Si el signo es 0, +0 (código 3); si es 1, -0 (código 4)
            X_special_case = (X[E+M]) ? CASE_ZERO_N : CASE_ZERO_P;
        end
    end
end

// De manera análoga, se identifican en paralelo los casos especiales de Y
always_comb begin
    Y_special_case = 0;
    if (Y[E+M-1:0] == {E+M{1'b1}}) begin
        // Si el signo es 0, +inf (código 1); si es 1, -inf (código 2)
        Y_special_case = (Y[E+M]) ? CASE_INF_N : CASE_INF_P;
    end 
    else if (Y[E+M-2:0] == {E+M-1{1'b0}}) begin
        // Si el MSB del exponente es 1, es un caso especial de +1/-1. En caso contrario, +0/-0
        if (Y[E+M-1]) begin
            // Si el signo es 0, +1 (código 5); si es 1, -1 (código 6)
            Y_special_case = (Y[E+M]) ? CASE_ONE_N : CASE_ONE_P;
        end
        else begin
            // Si el signo es 0, +0 (código 3); si es 1, -0 (código 4)
            Y_special_case = (Y[E+M]) ? CASE_ZERO_N : CASE_ZERO_P;
        end
    end
end
endmodule