/* Module: special_cases_detector

 Summary:
     Identifies special floating-point values such as ±infinity, ±zero, and ±one in operands X and Y.

 Parameters:
     M - Mantissa width.
     E - Exponent width.
     special_case - Number of supported special cases (including non-special case).

 Ports:
     X - First operand (in custom floating-point format).
     Y - Second operand (in custom floating-point format).
     X_special_case - Encoded identifier of the special case for operand X (0 = not special).
     Y_special_case - Encoded identifier of the special case for operand Y (0 = not special).
     X_one - Indicates if operand X is ±one.
 */
module special_cases_detector #(
    parameter int M = 23,
    parameter int E = 8,
    parameter int special_case = 7
)(              
    input logic clk,
    input logic rst_l,
    input logic [E+M:0] X,
    input logic [E+M:0] Y,
    output logic [$clog2(special_case)-1:0] X_special_case,
    output logic [$clog2(special_case)-1:0] Y_special_case,
    output logic X_one
);

/**
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
Section: Detection of special cases

This section detects whether operand X is a special floating-point value, such as:

- ±infinity: represented by all ones in the exponent and mantissa

- ±zero: represented by all zeros in the exponent and mantissa

- ±one: represented by an exponent of 1 and a mantissa of 0

Based on bit pattern analysis, the logic identifies the category of X and assigns a corresponding
identifier code (*X_special_case*). This code is later used to determine if a special result
must be returned by the floating-point adder.

The same logic is reused for operand Y without repeating the description.
*/
always_comb begin
    X_special_case = 0;
    X_one = 0;

    if (X[E+M-1:0] == {E+M{1'b1}}) begin
        // Infinity case (exponent and mantissa all 1s)
        X_special_case = (X[E+M]) ? CASE_INF_N : CASE_INF_P;
    end 
    else if (X[E+M-2:0] == {E+M-1{1'b0}}) begin
        // Check MSB of exponent to distinguish between ±1 and ±0
        if (X[E+M-1]) begin
            // X is ±1
            X_one = 1'b1;
        end
        else begin
            X_special_case = (X[E+M]) ? CASE_ZERO_N : CASE_ZERO_P;
        end
    end
end

always_comb begin
    Y_special_case = 0;

    if (Y[E+M-1:0] == {E+M{1'b1}}) begin
        Y_special_case = (Y[E+M]) ? CASE_INF_N : CASE_INF_P;
    end 
    else if (Y[E+M-2:0] == {E+M-1{1'b0}}) begin
        if (Y[E+M-1]) begin
            Y_special_case = (Y[E+M]) ? CASE_ONE_N : CASE_ONE_P;
        end
        else begin
            Y_special_case = (Y[E+M]) ? CASE_ZERO_N : CASE_ZERO_P;
        end
    end
end

endmodule