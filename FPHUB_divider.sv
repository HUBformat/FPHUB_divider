/*Title: Main module FPHUB Divider

  Floating-point SRT divider for HUB format.
*/

/* Module: FPHUB_divider
 
  Summary:
      Implements a floating-point radix-2 SRT divider for HUB format

  Parameters:
      M - Width of the mantissa.
      E - Width of the exponent.
      N - Number of iterations.
      special_case - Number of special case identifiers (e.g., 0 = none, 1 = +inf, etc.).
      sign_mantissa_bit - Width of the sign bit added to mantissa extension.
      one_implicit_bit - Implicit leading one in normalized mantissas.
      ilsb_bit - Extra bit for rounding support (Implicit Least Significant Bit).
      extra_int_bit - Extra bit for the integer part of the number.
      extra_bits_mantissa - Total number of extra bits added to the mantissa.
 
  Ports:
      clk - System clock.
      rst_l - reset signal (active low).
      start - Initiates the operation.
      x - First operand in HUB floating-point format.
      d - Second operand in HUB floating-point format.
      res - Result of the floating-point division.
      finish - Indicates the operation is complete.
      computing - Indicates the operation is in progress.
 */
module FPHUB_divider #(
    parameter int M = 23,
    parameter int E = 8,
    parameter int N = E + M, 
    parameter int special_case = 7,
    parameter int sign_mantissa_bit = 1,
    parameter int one_implicit_bit = 1,
    parameter int ilsb_bit = 1,
    parameter int extra_int_bit = 1,
    parameter int extra_bit_x_mayorque_d = 1,
    parameter int extra_bits_mantisa = sign_mantissa_bit + one_implicit_bit + ilsb_bit + extra_int_bit + extra_bit_x_mayorque_d
)(
    input  logic        clk,        
    input  logic        rst_l,     
    input  logic        start,    
    input  logic [M+E:0] x,          
    input  logic [M+E:0] d,          
    output logic [M+E:0] res,      
    output logic        finish,       
    output logic        computing
);

    /* Section: Special Case Handling

    Detects if either operand is a special floating-point value (e.g., ±0, ±1, ±inf).
    A special case detector module identifies the category for each operand.
    If a special case is detected, a dedicated result is computed using a separate module.
    This mechanism ensures correct handling of exceptions before further computation.
    
    Modules:
        The modules used are:

            - <special_cases_detector>: Detects ones, zeros, and infinities in the operands.

            - <special_result_for_divider>: Computes the output for those special inputs for division.
    */

    /* Variable: special_result
        Stores the result of the operation when a special case is detected.
    */
    logic [M+E:0] special_result;

    /* Variable: x_special_case
        Encodes the type of special case for operand x.
    */
    logic [$clog2(special_case)-1:0] x_special_case;

    /* Variable: d_special_case
        Encodes the type of special case for operand d.
    */
    logic [$clog2(special_case)-1:0] d_special_case;

    /* Variable: special_case_detected
        Flag indicating whether a special case has been detected.
    */
    logic special_case_detected;
    assign special_case_detected = start && (x_special_case | d_special_case); 

    special_cases_detector #(E,M,special_case) special_cases_inst (
        .X(x),
        .Y(d),
        .X_special_case(x_special_case),
        .Y_special_case(d_special_case)
    );

    special_result_for_divider #(E, M, special_case) special_result_inst (
    .X(x),
    .Y(d),
    .X_special_case(x_special_case),
    .Y_special_case(d_special_case),
    .special_result(special_result)
    );


    /* Section: Intermediate Signals declaration

    Creation and assignment of different intermediate signals to be used later during the algorithm.
    
    */
    
     /* Variable: q (quotient)
        Array containing the digits of the SRT quotient (-1,0,1).
    */
    int  q [N+1];      

    /* Variable: iter_count
        Counter for the number of iterations.
    */
    logic [$clog2(N+1)-1:0] iter_count; 


    /* Variable: x_sign, d_sign
        Bits containing the sign of operands x and d.
    */
    logic x_sign, d_sign;

    assign x_sign = x[M+E];
    assign d_sign = d[M+E]; 

    /* Variable: x_mantissa, d_mantissa
        Mantissas of operands x and d.
    */
    logic[one_implicit_bit + M + ilsb_bit + extra_bit_x_mayorque_d:0] x_mantissa, d_mantissa;
    
    assign x_mantissa =  {1'b1, x[M-1:0], 1'b1, 1'b0, 1'b0}; 
    assign d_mantissa =  {1'b1, d[M-1:0], 1'b1, 1'b0, 1'b0};

    /* Variable: x_exponent, d_exponent
        Exponents of operands x and d.
    */
    logic[E-1:0]  x_exponent, d_exponent;

    assign x_exponent = x[M+E-1:M];
    assign d_exponent = d[M+E-1:M];
    
    /* Variable: w_current, w_next, w_current_2
        Variables containing the current remainder, the remainder of the next iteration of the algorithm, and the current remainder multiplied by 2.

        These fields are formed by the sign, 1 extra bit for the integer part of the number, the implicit 1 from IEEE-754, the HUB mantissa and one extra fractional bit

        In 32-bit format, this translates to:  Sign bit + Extra int bit + Implicit 1 bit from IEEE-754 + 24 bits from HUB mantissa + Extra fractional bit -> 28 bits
    */
    logic signed [M+extra_bits_mantisa:0] w_current, w_next, w_current_2; 
    
    assign w_current_2 = {w_current[M+extra_bits_mantisa], shifted_w_current[M+extra_bits_mantisa-1:0]}; 

    /* Variable: d_signed
        Field containing the HUB value of operand d. It has the same format as <w_current, w_next, w_current_2>
    */
    logic signed [M+extra_bits_mantisa:0] d_signed;

    /* Variable: posiv
        Signal containing the positions in which que quotient <q> has a 1
    */
    logic [N:0] posiv;

    /* Variable: neg
        Signal containing the positions in which que quotient <q> has a -1
    */
    logic [N:0] neg;

    logic [M+extra_bits_mantisa:0] shifted_w_current;
    assign shifted_w_current = w_current << 1;


    /* Section: Fixed-point to floating-point conversion signals
        Once the value has been computed, it must be formatted back to floating-point
    */

    /* Variable: quotient
        quotient obtained from the SRT algorithm
    */
    logic [M+E:0] quotient;

    /* Variable: restored_quotient
        final quotient of the operation. It is obtained by multiplying by 2 the original <quotient>.
        
        The reason for this is that the first w value is obtained by dividing by 2 the operand x.
    */
    logic [M+E:0] restored_quotient;

    
    /* Variable: res_sign
        Sign of the computed value
    */
    logic res_sign;

    /* Variable: res_exponent
        Exponent of the computed value
    */
    logic [E-1:0] res_exponent;
    logic signed [E+1:0] exponent_bound;

    /* Variable: res_mantissa
        Mantissa of the computed value
    */
    logic [M-1:0] res_mantissa;

    /* Variable: abs_fixed
        Absolute value of the <restored_quotient>
    */
    logic [M+E:0] abs_fixed;
    
    /* Variable: leading_zeros
        Number of leading zeros in the absolute value of the restored quotient
    */
    int leading_zeros;

    /* Variable: normalized
        Normalized value of the restored quotient, used to obtain the <res_mantissa>
    */
    logic [M+E:0] normalized;
    
    /* Variable: float_result
        Computed value reconstructed to floating-point format
    */
    logic [M+E:0] float_result;

    // Main algorithm
    always_comb begin   

        /*-------------------------
              Initialization
        -------------------------*/

        // If a new operation starts and it is NOT a special case
        if (start && !computing) begin
            posiv = '0;
            neg = '0;
        end
            
            
        /*--------------------------------
               Termination Phase of SRT
        ---------------------------------*/

        if(iter_count == N) begin
            
            // Obtain the positions in which quotient q has a 1 or a -1
            for (int i = 1; i <= N; i++) begin
                if (q[i] == 1) begin
                    posiv[N-i] = 1; 
                end
                else if (q[i] == -1) begin
                    neg[N-i] = 1;
                end

            end

            // If final remainder is negative
            if (w_current[M+extra_bits_mantisa]) begin
                quotient = (posiv - neg) -1'b1;
            end else begin
                quotient = posiv - neg;
            end
            
            // Obtain the final quotient by multiplying by 2 
            restored_quotient = quotient << 1;     

            // Count leading zeros
            leading_zeros = 0;    
            for (int i = M+E; i >= 0; i--) begin
                if (restored_quotient[i] == 1) break;
                leading_zeros = leading_zeros + 1;
            end
                    
            // Normalize the fixed-point value
            normalized = restored_quotient << leading_zeros;
                    
            // Extract mantissa, drop the implicit 1
            res_mantissa = normalized[M+E-1:E];           
        end

    end
    
    /* ---------------------------
         Sequential Logic
    ----------------------------*/

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            // Reset all registers
            iter_count <= '0;
            computing <= 1'b0;
            w_current <= '0;    
            res_sign <= 1'b0;
            res <= '0;
            finish <= 1'b0;
            res_exponent <= '0;
            exponent_bound <= '0;
            res_sign <= 1'b0;
        end
        else begin

            // If the result exponent is out of bounds
            if (exponent_bound < $signed(9'd0)) begin
                    finish <= 1'b1;
                    res <= {res_sign, 31'd0};
                    exponent_bound <= '0; // to avoid repeated execution
                    computing <= 1'b0; 
                end else if (exponent_bound > $signed(9'd255)) begin
                    finish <= 1'b1;
                    res <= {res_sign, 31'h7fffffff};
                    exponent_bound <= '0;
                    computing <= 1'b0; 
                end 

            // If a new operation starts and it IS a special case
            else if (start && !computing && special_case_detected) begin
                res <= special_result;   
                finish <= 1'b1;
            end else 

            // if a new operation begins and it is NOT a special case
            if (start &&  !computing && !special_case_detected) begin
                
                    iter_count <= '0;
                    computing <= 1'b1;
                    res_sign <= x_sign ^ d_sign; 
                    finish <= 1'b0;
                    res <= '0;

                    // W_current: Positive sign + extra int bit + mantissa
                    
                    // In SRT algorithm, the first remainder is obtained dividing by 2 the original value
                    // BUT if x_mantissa is greater than d_mantissa, we must divide it again and update the exponent
                    if (x_mantissa > d_mantissa) begin  
                        w_current <= {1'b0, 1'b0, (x_mantissa >> 2)};  //
                        exponent_bound <= (x_exponent) - d_exponent + 8'd128;
                        res_exponent <=  (x_exponent) - d_exponent + 8'd128;   
                    end else begin
                        w_current <= {1'b0, 1'b0, (x_mantissa >> 1)}; 
                        exponent_bound <= x_exponent-d_exponent + 8'd127;
                        res_exponent <= x_exponent-d_exponent + 8'd127;
                    end
                    
                    
                    // Positive sign + extra int bit + mantissa
                    d_signed <= {1'b0, 1'b0, d_mantissa}; 


           // If there is an operation in progress
            end else if (computing && iter_count < N) begin
                iter_count <= iter_count +1;

                // if current w*2 is greater or equal to 0.5
                if((!w_current_2[28]) && w_current_2[27:26] >= 2'b01) begin  
                    q[iter_count+1] <= 1;                          
                    w_current <= w_current_2 - d_signed;         

                // if current w*2 is lower than -0.5
                end else if ((w_current_2[28]) && w_current_2[27:26] >=  2'b01) begin  
                    q[iter_count+1] <= -1;
                    w_current <= w_current_2 + d_signed;    
                    
                //if current w*2 is greater or equal to -0.5 and lower than 0.5
                end else begin
                    q[iter_count+1] <= 0;
                    w_current <= w_current_2;
                end

            end else if (iter_count == N) begin

                res <= {res_sign, res_exponent, res_mantissa};
                computing <= 1'b0;
                iter_count <= '0;
                finish <= 1'b1;
            end else begin
                finish <= 1'b0;
                res <= '0;
            end
       
            
        end
    end

endmodule