/* Module: special_result_for_divider

 Summary:
     Generates the results for the special cases of the division.

 Parameters:
     M - Mantissa width.
     E - Exponent width.
     special_case - Number of supported special cases (including non-special case).

 Ports:
     X - First operand (in custom floating-point format).
     Y - Second operand (in custom floating-point format).
     X_special_case - Encoded identifier of the special case for operand X (0 = not special).
     Y_special_case - Encoded identifier of the special case for operand Y (0 = not special).
     special_result - Result of the special case (in custom floating-point format).
 */

module special_result_for_divider #(
    parameter int M = 23,                                       
    parameter int E = 8,                                       
    parameter int special_case = 7                              
)(              
    input logic [E+M:0] X,                                      
    input logic [E+M:0] Y,                                      
    input logic [$clog2(special_case)-1:0] X_special_case,      
    input logic [$clog2(special_case)-1:0] Y_special_case,   
    output logic [E+M:0] special_result                        
);

/*
    Section: Special case identifiers
    Constant encoding of recognized special cases.
*/
localparam logic [$clog2(special_case):0] CASE_NONE   = 0;
localparam logic [$clog2(special_case):0] CASE_INF_P  = 1;
localparam logic [$clog2(special_case):0] CASE_INF_N  = 2;
localparam logic [$clog2(special_case):0] CASE_ZERO_P = 3;
localparam logic [$clog2(special_case):0] CASE_ZERO_N = 4;
localparam logic [$clog2(special_case):0] CASE_ONE_P  = 5;
localparam logic [$clog2(special_case):0] CASE_ONE_N  = 6;

/*
    Section: Result constants
*/
localparam logic [E+M-1:0] INF  = {{E{1'b1}}, {M{1'b1}}}; 
localparam logic [E+M-1:0] ZERO = {(E+M){1'b0}};

/*
    Section: Intermediate signals
*/
logic result_sign;
logic is_x_inf, is_x_zero, is_x_one, is_x_normal;
logic is_y_inf, is_y_zero, is_y_one, is_y_normal;
logic is_inf_div_inf, is_zero_div_zero;
logic is_norm_div_inf, is_zero_div_norm, is_norm_div_zero;
logic is_inf_div_norm, is_norm_div_one;

// Operand classification
assign is_x_inf    = (X_special_case == CASE_INF_P) || (X_special_case == CASE_INF_N);
assign is_x_zero   = (X_special_case == CASE_ZERO_P) || (X_special_case == CASE_ZERO_N);
assign is_x_one    = (X_special_case == CASE_ONE_P) || (X_special_case == CASE_ONE_N);
assign is_x_normal = (X_special_case == CASE_NONE);

assign is_y_inf    = (Y_special_case == CASE_INF_P) || (Y_special_case == CASE_INF_N);
assign is_y_zero   = (Y_special_case == CASE_ZERO_P) || (Y_special_case == CASE_ZERO_N);
assign is_y_one    = (Y_special_case == CASE_ONE_P) || (Y_special_case == CASE_ONE_N);
assign is_y_normal = (Y_special_case == CASE_NONE);

// Special case combinations
assign is_inf_div_inf   = is_x_inf && is_y_inf;
assign is_zero_div_zero = is_x_zero && is_y_zero;
assign is_norm_div_inf  = is_x_normal && is_y_inf;
assign is_zero_div_norm = is_x_zero && (is_y_normal || is_y_one);
assign is_norm_div_zero = (is_x_normal || is_x_one) && is_y_zero;
assign is_inf_div_norm  = is_x_inf && (is_y_normal || is_y_one);
assign is_norm_div_one  = (is_x_normal || is_x_inf || is_x_zero) && is_y_one;

// Sign of the result
assign result_sign = X[M+E] ^ Y[M+E];

/*
    Section: Special case logic
    
    Division special cases:
    - Inf / Inf = NaN
    - 0 / 0 = NaN
    - Normal / Inf = 0 
    - 0 / Normal = 0 
    - Normal / 0 = Inf 
    - Inf / Normal = Inf 
    - Normal / 1 = Normal
    - Inf / 0 = Inf
    - 0 / Inf = 0
*/

always_comb begin
    // Default to NaN
    special_result = {1'b0, INF};
    
    if (is_inf_div_inf || is_zero_div_zero) begin
        // Inf/Inf or 0/0 = NaN 
        special_result = {1'b1, INF};
    end
    else if (is_norm_div_zero || (is_inf_div_norm)) begin
        // Normal/0 or Inf/Normal = signed Inf
        special_result = {result_sign, INF};
    end
    else if (is_norm_div_inf || is_zero_div_norm) begin
        // Normal/Inf or 0/Normal = signed 0
        special_result = {result_sign, ZERO};
    end
    else if (is_norm_div_one) begin
        // Normal/1 = Normal
        special_result = {result_sign, X[M+E-1:0]};
    end
    else if (is_x_zero && is_y_inf) begin
        // 0/Inf = signed 0
        special_result = {result_sign, ZERO};
    end
    else if (is_x_inf && is_y_zero) begin
        // Inf/0 = signed Inf
        special_result = {result_sign, INF};
    end
    else if (is_x_zero && is_y_zero) begin
        // 0/0 = NaN
        special_result = {1'b0, INF};
    end
    else begin
        // No special case detected
        special_result = {1'b0, ZERO};
    end
end

endmodule