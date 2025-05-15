/* Module: special_result_for_divider

 Summary:
     Generates the final result of the adder when at least one operand is a special case
     (e.g., ±infinity, ±zero). Handles cases like Inf + Inf or Inf - Inf.

 Parameters:
     M - Mantissa width.
     E - Exponent width.
     special_case - Number of supported special cases.

 Ports:
     X - Operand X (custom floating-point format).
     Y - Operand Y (custom floating-point format).
     X_special_case - Code identifying if X is a special case (0 = not special).
     Y_special_case - Code identifying if Y is a special case (0 = not special).
     special_result - Result of the operation considering only the special cases.
 */
module special_result_for_adder #(
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
 Section: Special case identifiers

 Constant encoding of recognized special cases.
 */

 /**
 * Variable: CASE_NONE
 *     No special case.
 */
localparam logic [$clog2(special_case):0] CASE_NONE = 0;

/**
 * Variable: CASE_INF_P
 *     Positive infinity.
 */
localparam logic [$clog2(special_case):0] CASE_INF_P = 1;

/**
 * Variable: CASE_INF_N
 *     Negative infinity.
 */
localparam logic [$clog2(special_case):0] CASE_INF_N = 2;

/**
 * Variable: CASE_ZERO_P
 *     Positive zero.
 */
localparam logic [$clog2(special_case):0] CASE_ZERO_P = 3;

/**
 * Variable: CASE_ZERO_N
 *     Negative zero.
 */
localparam logic [$clog2(special_case):0] CASE_ZERO_N = 4;

/**
 * Variable: CASE_ONE_P
 *     Positive one.
 */
localparam logic [$clog2(special_case):0] CASE_ONE_P = 5;

/**
 * Variable: CASE_ONE_N
 *     Negative one.
 */
localparam logic [$clog2(special_case):0] CASE_ONE_N = 6;

/**
 Section: Special result constants

 Constant encoding of special results for the adder.
 These are used when at least one operand is a special case.

 --- Code
 localparam logic [E+M:0] 
    POS_INF  = {1'b0, {E{1'b1}}, {M{1'b1}}},
    NEG_INF  = {1'b1, {E{1'b1}}, {M{1'b1}}},
    POS_ZERO = {1'b0, {E+M{1'b0}}},
    NEG_ZERO = {1'b1, {E+M{1'b0}}};
 ---
*/

localparam logic [E+M:0] 
    POS_INF  = {1'b0, {E{1'b1}}, {M{1'b1}}},
    NEG_INF  = {1'b1, {E{1'b1}}, {M{1'b1}}},
    POS_ZERO = {1'b0, {E+M{1'b0}}},
    NEG_ZERO = {1'b1, {E+M{1'b0}}};

/*
Section: Special result generation

This block selects the correct result when one or both operands are classified as special cases.

It covers combinations such as:

- x / Zero  → returns neg infinity

- x / 1     → returns x

- x / inf   → returns zero

- inf / inf → returns neg infinity

This mechanism ensures that special cases are handled deterministically before any general arithmetic is performed.
It allows the rest of the floating-point divider to assume that both operands are normal if this path is not taken.
*/
always_comb begin
    if (X_special_case == CASE_ZERO_N || X_special_case == CASE_ZERO_P) begin
        special_result = NEG_INF;
    end
    else if (Y_special_case == CASE_ONE_P) begin
        special_result = X;
    end 
    else if ((X_special_case != CASE_INF_N && X_special_case != CASE_INF_P) && (Y_special_case == CASE_INF_N || Y_special_case == CASE_INF_P)) begin
        special_result = POS_ZERO;
    end
    else if ((X_special_case == CASE_INF_N || X_special_case == CASE_INF_P) && (Y_special_case == CASE_INF_N || Y_special_case == CASE_INF_P)) begin
        special_result = NEG_INF;
    end

end

endmodule