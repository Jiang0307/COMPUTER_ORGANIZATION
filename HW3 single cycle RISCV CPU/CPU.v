module CPU(clk , rst , data_out , instr_out , instr_read , data_read , instr_addr , data_addr , data_write , data_in);
input             clk;
input             rst;
input      [31:0] data_out;
input      [31:0] instr_out;
output reg        instr_read;
output reg        data_read;
output reg [31:0] instr_addr;  
output reg [31:0] data_addr;
output reg [3:0]  data_write; //用來看現在是否要寫入(SW)
output reg [31:0] data_in; 

reg lh , lhu;
reg [1:0] lb , lbu;
reg [2:0] funct3 , current_state;
reg [4:0] rs1, rs2, rd, shamt;
reg [6:0] funct7, opcode; //self defined
reg [31:0] pc , imm; //11bit sign extend to 32 bit
reg [63:0] mul_result , mulh_result , mulhu_result;
reg [31:0] register[31:0];
parameter INSTRUCTION_READ='d1 , DECODE='d2 , HALF='d3 , PARAMETER_LOAD='d4 , LOAD='d5;

always @(posedge clk)
begin
    register[0] <= 32'd0;
    if(rst == 1'b1)
    begin
        pc <= 32'h0;
        instr_read <= 1'b1;
        instr_addr <= 32'h0;
        data_read <= 1'b0;
        data_write <= 4'b0000;
        imm <= 32'b0;
        current_state <= INSTRUCTION_READ;
    end
    else
    begin
        case(current_state)
            PARAMETER_LOAD: current_state <= LOAD; //L-type延遲一個cycle 確保讀得到東西
            INSTRUCTION_READ:
            begin
                data_write <= 4'b0000;
                instr_read <= 1'd1;
                pc <= instr_addr;
                current_state <= DECODE;
            end
            DECODE:
            begin
                instr_read = 1'b0;
                {funct7, rs2, rs1, funct3, rd, opcode} = instr_out;
                case(opcode)
                    7'b0110011://R-type
                    begin
                        case({funct7,funct3})
                            10'b0000000000: register[rd] <= register[rs1] + register[rs2]; //ADD
                            10'b0100000000: register[rd] <= register[rs1] - register[rs2]; //SUB
                            10'b0000000001: register[rd] <= $unsigned(register[rs1]) << register[rs2][4:0]; //SLL
                            10'b0000000010: register[rd] <= ($signed(register[rs1]) < $signed(register[rs2])) ? 'd1 : 'd0; //SLT
                            10'b0000000011: register[rd] <= ($unsigned(register[rs1]) < $unsigned(register[rs2])) ? 'd1 : 'd0; //SLTU
                            10'b0000000100: register[rd] <= register[rs1] ^ register[rs2]; //XOR
                            10'b0000000101: register[rd] <= $unsigned(register[rs1]) >> register[rs2][4:0]; //SRL
                            10'b0100000101: register[rd] <= $signed(register[rs1]) >> register[rs2][4:0];	//SRA
                            10'b0000000110: register[rd] <= register[rs1] | register[rs2]; //OR
                            10'b0000000111: register[rd] <= register[rs1] & register[rs2]; //AND
                            10'b0000001000: //MUL
                            begin
                                mul_result = $signed(register[rs1]) * $signed(register[rs2]);
                                register[rd] =  mul_result[31:0];
                            end 
                            10'b0000001001: //MULH
                            begin
                                mulh_result = $signed(register[rs1]) * $signed(register[rs2]);
                                register[rd] = mulh_result[63:32];
                            end 
                            10'b0000001011: //MULHU
                            begin
                                mulhu_result = $unsigned(register[rs1]) * $unsigned(register[rs2]);
                                register[rd] = mulhu_result[63:32];
                            end 
                        endcase
                        pc = pc + 32'h4;
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        data_write = 4'b0000;
                        current_state = INSTRUCTION_READ;
                    end
                    7'b0000011: //L-type
                    begin
                        {rs1, funct3, rd} <= instr_out[19:7];
                        imm <= {{20{instr_out[31]}}, instr_out[31:20]};
                        current_state <= HALF;
                    end
                    7'b0010011: //I-type
                    begin
						{rs1, funct3, rd} <= instr_out[19:7];
						imm <= { {20{instr_out[31]}} , instr_out[31:20] };
						shamt <= instr_out[24:20];
                        current_state <= HALF;
                    end
					7'b1100111:	//JALR
					begin
                        {rs1, funct3, rd} <= instr_out[19:7];
                        imm <= { {20{instr_out[31]}} , instr_out[31:20] };
                        current_state <= HALF;
					end
                    7'b0100011: //S-type
                    begin
                        {rs2,rs1,funct3} = instr_out[24:12];
                        imm = {{20{instr_out[31]}}, instr_out[31:25], instr_out[11:7]};
                        data_addr = register[rs1] + imm;
                        current_state = HALF;
                    end
                    7'b1100011: //B-type
                    begin
                        {rs2 , rs1 , funct3} <= instr_out[24:12];
                        imm <= { {19{instr_out[31]}} , instr_out[31] , instr_out[7] , instr_out[30:25] , instr_out[11:8] , 1'b0};
                        current_state <= HALF;
                    end
                    7'b0010111: //AUIPC
                    begin
                        {rd} <= instr_out[11:7];
                        imm <= { instr_out[31:12] , 12'b0 };
                        current_state <= HALF;
                    end
                    7'b0110111: //LUI
                    begin
                        {rd} <= instr_out[11:7];
                        imm <= { instr_out[31:12] , 12'b0 };
                        current_state <= HALF;
                    end
                    7'b1101111: //JAL
                    begin
                        {rd} <= instr_out[11:7];
                        imm <= { {11{instr_out[31]}} , instr_out[31] , instr_out[19:12] , instr_out[20] , instr_out[30:21] , 1'b0};
                        current_state <= HALF;
                    end
                endcase
            end
            HALF://處理R-type以外 其他只完成一半步驟的
            begin
                case(opcode)
                    7'b0000011: //L-type
                    begin
                        case(funct3)
                            3'b010: //LW
                            begin
                                data_read <= 1'b1;
                                data_addr <= register[rs1] + imm;
                            end
                            3'b000: //LB
                            begin
                                data_read <= 1'b1;
                                data_addr <= register[rs1] + imm;
                                lb <= data_addr[1:0]; //lb用來處理到時候 register[rd] <= data_out 的哪個byte，取出該byte後signed extend至32bit
                                data_addr <= {data_addr[31:2] , 2'b00};
                            end
                            3'b001: //LH
                            begin
                                data_read <= 1'b1;
                                data_addr <= register[rs1] + imm;
                                lh <= data_addr[0];
                                data_addr <= {data_addr[31:1] , 1'b0};
                            end
                            3'b100: //LBU
                            begin
                                data_read <= 1'b1;
                                data_addr <= register[rs1] + imm;
                                lbu <= data_addr[1:0]; //lb用來處理到時候 register[rd] <= data_out 的哪個byte，取出該byte後signed extend至32bit
                                data_addr <= {data_addr[31:2] , 2'b00};
                            end
                            3'b101: //LHU
                            begin
                                data_read <= 1'b1;
                                data_addr <= register[rs1] + imm;
                                lhu <= data_addr[0];
                                data_addr <= {data_addr[31:1] , 1'b0};
                            end
                        endcase
                        pc <= pc + 32'h4;
                        current_state <= PARAMETER_LOAD;
                    end
                    7'b0010011: //I-type
                    begin
                        case(funct3)
                            3'b000: register[rd] <= register[rs1] + imm; //ADDI
                            3'b010: register[rd] <= ($signed(register[rs1]) < $signed(imm)) ? 'd1 : 'd0; //SLTI
                            3'b011: register[rd] <= ($unsigned(register[rs1]) < $unsigned(imm)) ? 'd1 : 'd0; //SLTIU
                            3'b100: register[rd] <= register[rs1] ^ imm; //XORI
                            3'b110: register[rd] <= register[rs1] | imm; //ORI
                            3'b111: register[rd] <= register[rs1] & imm; //ORI
                            3'b001: register[rd] <= $unsigned(register[rs1]) << shamt; //SLLI
                            3'b101: 
                            begin
                                case(imm[11:5])
                                    7'b0000000: register[rd] <= $unsigned(register[rs1]) >> shamt; //SRLI
                                    7'b0100000: register[rd] <= $signed(register[rs1]) >>> shamt; //SRAI
                                endcase
                            end
                        endcase
                        pc = pc + 32'h4;
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        data_write = 4'b0000;
                        current_state = INSTRUCTION_READ;
                    end
                    7'b0100011: //S-type
                    begin
                        case(funct3)
                            3'b010: //SW
                            begin
                                data_write <= 4'b1111;
                                data_in <= register[rs2];
                            end
                            3'b000: //SB
                            begin
                                case(data_addr[1:0])
                                    2'b00:
                                    begin
                                        data_write <= 4'b0001;
                                        data_in[7:0] <= register[rs2][7:0];
                                    end
                                    2'b01:
                                    begin
                                        data_write <= 4'b0010;
                                        data_in[15:8] <= register[rs2][7:0];
                                    end
                                    2'b10:
                                    begin
                                        data_write <= 4'b0100;
                                        data_in[23:16] <= register[rs2][7:0];
                                    end
                                    2'b11:
                                    begin
                                        data_write <= 4'b1000;
                                        data_in[31:24] <= register[rs2][7:0];
                                    end
                                endcase
                            end
                            3'b001: //SH
                            begin
                                if( (data_addr % 4 ) == 'd0 ) //rightmost halfword
                                begin
                                    data_write <= 4'b0011;
                                    data_in <= { 16'b0 , register[rs2][15:0] };
                                end
                                else //leftmost halfword
                                begin
                                    data_write <= 4'b1100;
                                    data_in <= { register[rs2][15:0] , 16'b0 };
                                end
                            end
                        endcase
                        pc = pc + 32'h4;
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        current_state = INSTRUCTION_READ;
                    end
                    7'b1100011: //B-type
                    begin
                        case(funct3)
                            3'b000: pc = (register[rs1] == register[rs2]) ? (pc + imm) : (pc + 32'h4);	//BEQ
                            3'b001: pc = (register[rs1] != register[rs2]) ? (pc + imm) : (pc + 32'h4);	//BNE
                            3'b100: pc = ($signed(register[rs1]) < $signed(register[rs2])) ? (pc + imm) : (pc + 32'h4); //BLT
                            3'b101: pc = ($signed(register[rs1]) >= $signed(register[rs2])) ? (pc + imm) : (pc + 32'h4); //BGE
                            3'b110: pc = ($unsigned(register[rs1]) < $unsigned(register[rs2])) ? (pc + imm) : (pc + 32'h4); //BLTU       
                            3'b111: pc = ($unsigned(register[rs1]) >= $unsigned(register[rs2])) ? (pc + imm) : (pc + 32'h4); //BGEU
                        endcase
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        data_write = 4'b0000;
                        current_state = INSTRUCTION_READ;
                    end
                    7'b0010111: //AUIPC
                    begin
                        register[rd] <= pc + imm;
                        pc = pc + 32'h4;
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        data_write = 4'b0000;
                        current_state = INSTRUCTION_READ;
                    end
                    7'b0110111: //LUI
                    begin
                        register[rd] <= imm;
                        pc = pc + 32'h4;
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        data_write = 4'b0000;
                        current_state = INSTRUCTION_READ;
                    end
                    7'b1101111: //JAL
                    begin
                        register[rd] <= pc + 32'h4;
                        pc = pc + imm;
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        data_write = 4'b0000;
                        current_state = INSTRUCTION_READ;
                    end
                    7'b1100111: //JALR
                    begin
                        register[rd] <= pc + 32'h4;
                        pc = imm + register[rs1];
                        instr_addr = pc;
                        instr_read = 1'd1;
                        data_read = 1'b0;
                        data_write = 4'b0000;
                        current_state = INSTRUCTION_READ;
                    end
                endcase
            end
            LOAD: //L-type最後一個步驟
            begin
                case(funct3)
                    3'b010: //LW
                    begin
                        register[rd] <= data_out; //讀取data_out全部的bit
                    end
                    3'b000: //LB
                    begin
                        case(lb) //選擇要讀取data_out的哪個BYTE
                            2'b00: register[rd] <= { {24{data_out[7]}} , data_out[7:0] };
                            2'b01: register[rd] <= { {24{data_out[15]}} , data_out[15:8] };
                            2'b10: register[rd] <= { {24{data_out[23]}} , data_out[23:16] };
                            2'b11: register[rd] <= { {24{data_out[31]}} , data_out[31:24] };
                        endcase
                    end
                    3'b001: //LH
                    begin
                        case(lh) //選擇要讀取data_out的HALFWORD
                            1'b0: register[rd] <= { {16{data_out[15]}} , data_out[15:0] };
                            1'b1: register[rd] <= { {16{data_out[31]}} , data_out[31:16] };
                        endcase
                    end
                    3'b100: //LBU
                    begin
                        case(lbu) //選擇要讀取data_out的哪個BYTE
                            2'b00: register[rd] <= { 24'b0 , data_out[7:0] };
                            2'b01: register[rd] <= { 24'b0 , data_out[15:8] };
                            2'b00: register[rd] <= { 24'b0 , data_out[23:16] };
                            2'b00: register[rd] <= { 24'b0 , data_out[31:24] };
                        endcase
                    end
                    3'b101: //LHU
                    begin
                        case(lhu) //選擇要讀取data_out的HALFWORD
                            1'b0: register[rd] <= { 16'b0 , data_out[15:0] };
                            1'b1: register[rd] <= { 16'b0 , data_out[31:16] };
                        endcase
                    end
                endcase
                instr_addr = pc;
                instr_read = 1'd1;
                data_read = 1'b0;
                data_write = 4'b0000;
                current_state = INSTRUCTION_READ;
            end        
        endcase
    end
end
endmodule