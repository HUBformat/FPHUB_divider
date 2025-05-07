/*Title: Main module FPHUB Divider

  Floating-point divider for HUB format.
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
            extra_int_bit - dsfsdf.
      extra_bits_mantissa - Total number of extra bits added to the mantissa.
 
  Ports:
      clk - dsfdsf.
      rst_l - sfdsfds.
      start - Initiates the operation.
      x - First operand in HUB floating-point format.
      d - Second operand in HUB floating-point format.
      res - Result of the floating-point division.
      finish - Indicates the operation is complete.
      computing - dsfdsf.
      iter_count - dsfdsf.
      w_current - fewed.
      posiv - sdsdf.
      neg - ffdf.
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
    parameter int extra_bits_mantisa = sign_mantissa_bit + one_implicit_bit + ilsb_bit + extra_int_bit
)(
    input  logic        clk,        
    input  logic        rst_l,     
    input  logic        start,    
    input  logic [M+E:0] x,          
    input  logic [M+E:0] d,          
    output logic [M+E:0] res,       // Result output
    output logic        finish,       // Signal indicating division is complete
    output logic        computing,
    output logic [$clog2(M+E+1)-1:0] iter_count,
    output logic signed [M+extra_bits_mantisa:0] w_current,
    output logic [M+E:0] posiv, 
    output logic [M+E:0] neg
);

    logic [M+E:0] special_result;
    logic [$clog2(special_case)-1:0] X_special_case, Y_special_case;
    logic special_case_detected;

    special_cases_detector #(E,M,special_case) special_cases_inst (
        .X(x),
        .Y(d),
        .X_special_case(X_special_case),
        .Y_special_case(Y_special_case)
    );

    special_result_for_divider #(E, M, special_case) special_result_inst (
    .X(X),
    .Y(Y),
    .X_special_case(X_special_case),
    .Y_special_case(Y_special_case),
    .special_result(special_result)
    );

    assign special_case_detected = start && (X_special_case | Y_special_case); //TODO: revisar
    
    
    // Internal registers
    int  q [N+1];          // Signed digits (+1, -1) for each iteration
    //logic [$clog2(N+1)-1:0] iter_count;  // Counter for iterations

    logic x_sign, d_sign;
    logic[one_implicit_bit + M + ilsb_bit:0] x_mantisa, d_mantisa; 
    logic[E-1:0]  x_exponent, d_exponent;
    
    // Floating-point values for intermediate calculations
    logic signed [M+extra_bits_mantisa:0] /*w_current, */w_next, w_current_2, d_signed;   //1 sign + 1 Extra parte entera + 25 HUB (1 entero + 24 fraccion) + 1 extra (w(0)) -> 28 bits


    // Extract fields
    assign x_sign = x[M+E];
    assign d_sign = d[M+E]; 

    assign x_exponent = x[M+E-1:M];
    assign d_exponent = d[M+E-1:M];

    assign x_mantisa = (x_exponent == '0) ? 0 : {1'b1, x[M-1:0], 1'b1, 1'b0}; 
    assign d_mantisa = (d_exponent == '0) ? 0 : {1'b1, d[M-1:0], 1'b1, 1'b0};

    assign w_current_2 = {w_current[M+extra_bits_mantisa], shifted_w_current[M+extra_bits_mantisa-1:0]}; //TODO: revisar

    //logic [N:0] posiv, neg;

    logic [M+extra_bits_mantisa:0] shifted_w_current;
    assign shifted_w_current = w_current << 1;

    logic [M+E:0] quotient, restored_quotient;
    logic sign;
    logic [E-1:0] exponent;
    logic [M-1:0] mantissa;
    logic [M+E:0] float_result;
    int leading_zeros;
    logic [M+E:0] abs_fixed;
    logic [M+E:0] normalized;
 

    // Main algorithm
    always_comb begin   

        finish = 0;

        /*-------------------------
            Initialization
        -------------------------*/

        if (start && !computing && special_case_detected) begin
            res = special_result;
            finish=1;

        end else if (start && !computing) begin
            res= '0;
            posiv = '0;
            neg = '0;
            for (int i = 0; i<=N; i++) begin
                q[i] = 0;
            end

        end

        /*------------------------
            Main Algorithm
        -------------------------*/

        if (computing && iter_count < N) begin
            // if current w*2 is greater or equal to 0.5
            if(w_current_2 >= 28'sh1000000) begin  //Original
           //if(w_current_2 >= $signed(1 << (M+extra_bits_mantisa-1))) begin
                q[iter_count+1] = 1;    

            // if current w*2 is lower than -0.5
            end else if (w_current_2 < 28'shF000000)  begin  //Original
            //end else if (w_current_2 < $signed({1'b1, {(M+extra_bits_mantisa-4){1'b1}}, 4'b0000})) begin
                q[iter_count+1] = -1;

            //if current w*2 is greater or equal to -0.5 and lower than 0.5
            end else begin
                q[iter_count+1] = 0;
            end

            w_next = w_current_2 -q[iter_count+1]*d_signed;
        end

        /*----------------------------
            Termination Phase
        -----------------------------*/

        if(iter_count == N) begin
            
            posiv[N] = 0;
            neg[N] = 0;
            for (int i = 1; i <= N; i++) begin
                if (q[i] == 1) begin
                    posiv[N-i] = 1;
                    neg[N-i] = 0;
                end
                else if (q[i] == -1) begin
                    posiv[N-i] = 0;
                    neg[N-i] = 1;
                end

            
            // If final remainder is negative
            if (w_current[M+extra_bits_mantisa]) begin
                quotient = (posiv - neg) -1'b1;
                //TODO: remainder
            end else begin
                quotient = posiv - neg;
            end

            end
            

            /*--------------------------------------------------
                Fixed point to floating point conversion begin
            ---------------------------------------------------*/
            
            // Calculate the fixed point value
            restored_quotient = quotient << 1;
            
            // Extract sign bit
            sign = restored_quotient[M+E];
            
            // Handle special case: zero
            if (restored_quotient == '0) begin 
                res = '0; // Return zero in floating-point format
            end else begin
                // Take absolute value for processing
                abs_fixed = sign ? (~restored_quotient + 1'b1) : restored_quotient;
                
                // Count leading zeros
                leading_zeros = 0;
                for (int i = M+E; i >= 0; i--) begin
                    if (abs_fixed[i] == 1) break;
                    leading_zeros = leading_zeros + 1;
                end
                
                // Normalize the fixed-point value
                normalized = abs_fixed << leading_zeros;
                
                // Calculate exponent
                exponent = 8'd127 - leading_zeros; //TODO: revisar
                
                // Extract mantissa, drop the implicit 1
                mantissa = normalized[M+E-1:E];
                
                // Assemble IEEE 754 floating-point result
                float_result = {sign, exponent, mantissa};

            /*--------------------------------------------------
                Fixed point to floating point conversion end
            ---------------------------------------------------*/               
                res = float_result;
            end

            finish = 1;
        end

    end
    
    // Sequential logic
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            // Reset all registers
            iter_count <= '0;
            computing <= 1'b0;
            w_current <= '0;    
        end
        else begin


            if (start && !computing && !special_case_detected) begin
                // Initialize computation
                iter_count <= '0;
                computing <= 1'b1;
                w_current <= {x_sign, 1'b0, (x_mantisa >> 1)};
                
                d_signed = {d_sign, 1'b0, d_mantisa};

            end else if (computing && iter_count < N) begin
                iter_count <= iter_count +1;
                w_current <= w_next;
            end else begin
                computing <= 1'b0;
                iter_count <= '0;
            end
            
        end
    end

endmodule