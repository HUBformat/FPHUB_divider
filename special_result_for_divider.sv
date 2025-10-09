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

/**
    Variable: RES_SIGN
        Sign bit of the result.
*/
logic RES_SIGN;
assign RES_SIGN = X[M+E] ^ Y[M+E];

/*
    Section: Special case identifiers
    Constant encoding of recognized special cases.
*/

 /**
 * Constant: CASE_NONE
 *     No special case.
 */
localparam logic [$clog2(special_case):0] CASE_NONE = 0;

/**
 * Constant: CASE_INF_P
 *     Positive infinity.
 */
localparam logic [$clog2(special_case):0] CASE_INF_P = 1;

/**
 * Constant: CASE_INF_N
 *     Negative infinity.
 */
localparam logic [$clog2(special_case):0] CASE_INF_N = 2;

/**
 * Constant: CASE_ZERO_P
 *     Positive zero.
 */
localparam logic [$clog2(special_case):0] CASE_ZERO_P = 3;

/**
 * Constant: CASE_ZERO_N
 *     Negative zero.
 */
localparam logic [$clog2(special_case):0] CASE_ZERO_N = 4;

/**
 * Constant: CASE_ONE_P
 *     Positive one.
 */
localparam logic [$clog2(special_case):0] CASE_ONE_P = 5;

/**
 * Constant: CASE_ONE_N
 *     Negative one.
 */
localparam logic [$clog2(special_case):0] CASE_ONE_N = 6;

/*
    Constant: INF
        Constant representing infinity.
*/
localparam logic [E+M-1:0] INF = {{E{1'b1}}, {M{1'b1}}};    

/*
    Constant: ZERO
        Constant representing zero.
*/
localparam logic ZERO = {{E+M{1'b0}}};            

always_comb begin
    if (X_special_case == CASE_ZERO_P && Y_special_case == CASE_ZERO_P) begin
        special_result = {1'b1, INF};
    end
    else if (X_special_case == CASE_ZERO_N && Y_special_case == CASE_ZERO_N) begin
        special_result = {1'b1, INF};
    end
    else if (X_special_case == CASE_INF_P && Y_special_case == CASE_INF_P) begin
        special_result = {1'b1, INF};
    end
    // if X = -∞ and Y = -∞, result is -∞
    else if (X_special_case == CASE_INF_N && Y_special_case == CASE_INF_N) begin
        special_result = {1'b1, INF};
    end
    // Cases with infinity
    // if X = +∞ and Y = -∞, result is NaN
    else if ((X_special_case == CASE_INF_P && Y_special_case == CASE_INF_N) || (X_special_case == CASE_INF_N && Y_special_case == CASE_INF_P)) begin
        special_result = {RES_SIGN, INF}; 
    end   
    // if Y = +-∞, result is 0 
    else if (X_special_case == CASE_NONE && (Y_special_case == CASE_INF_P || Y_special_case == CASE_INF_N)) begin
        special_result = {RES_SIGN, ZERO};
    end
    // if Y = 0, result is NaN
   else if (Y_special_case == CASE_ZERO_N || Y_special_case == CASE_ZERO_P) begin
        special_result = {RES_SIGN, INF};
   end else if (X_special_case == CASE_ZERO_N || X_special_case == CASE_ZERO_P) begin
        special_result = {RES_SIGN, ZERO};
   end else if (Y_special_case == CASE_ONE_N || Y_special_case == CASE_ONE_P) begin
    special_result = {RES_SIGN, X[M+E-1:0]};
   end else if ((X_special_case == CASE_INF_P || X_special_case == CASE_INF_N)  && Y_special_case == CASE_NONE)begin
    special_result = {RES_SIGN, INF};

   end

end
endmodule
