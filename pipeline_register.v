module pipeline_register #(
    parameter int DATA_WIDTH = 32
) (
    input  logic                    clk,
    input  logic                    rst,  // Active-high reset
    
    // Input interface
    input  logic                    in_valid,
    output logic                    in_ready,
    input  logic [DATA_WIDTH-1:0]   in_data,
    
    // Output interface
    output logic                    out_valid,
    input  logic                    out_ready,
    output logic [DATA_WIDTH-1:0]   out_data
);

    // Internal storage
    logic [DATA_WIDTH-1:0] data_reg;
    logic                  valid_reg;
    
    // Handshake logic
    logic load_data;
    
    // Load data when:
    assign load_data = in_valid & in_ready;
    
    // Ready to accept input when:
    assign in_ready = !valid_reg | out_ready;
    
    // Output assignments
    assign out_valid = valid_reg;
    assign out_data  = data_reg;
    
    // Sequential logic
  always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_reg <= 1'b0;
            data_reg  <= '0;
        end else begin
            // Update valid flag
            if (load_data) begin
                valid_reg <= 1'b1;
            end else if (out_ready) begin
                valid_reg <= 1'b0;
            end
            
            // Load new data when handshake occurs
            if (load_data) begin
                data_reg <= in_data;
            end
        end
    end

endmodule