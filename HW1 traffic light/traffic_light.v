module traffic_light (clk,rst,pass,R,G,Y);
input clk,rst,pass;
output R,G,Y;

reg [2:0] current_state = 'd0;
reg [2:0] next_state;
reg [11:0] cycle = 'd1;
reg R = 'd0;
reg G = 'd1;
reg Y = 'd0;

always@(current_state)
begin
   case(current_state)
      'd0 :
      begin
         R <= 0;
         G <= 1;
         Y <= 0;
      end
      'd1 :
      begin
         R <= 0;
         G <= 0;
         Y <= 0;
      end
      'd2 :
      begin
         R <= 0;
         G <= 1;
         Y <= 0;
      end
      'd3 :
      begin
         R <= 0;
         G <= 0;
         Y <= 0;
      end
      'd4 :
      begin
         R <= 0;
         G <= 1;
         Y <= 0;
      end
      'd5 :
      begin
         R <= 0;
         G <= 0;
         Y <= 1;
      end
      'd6 :
      begin
         R <= 1;
         G <= 0;
         Y <= 0;
      end
   endcase
end

always@(posedge clk or posedge rst)
begin
   cycle <= cycle + 1;

   if(rst == 1)
   begin
      current_state <= 'd0;
      cycle <= 'd1;
   end
   
   if(pass == 1 && current_state != 'd0)
   begin
      current_state <= 'd0;
      cycle <= 'd1;
   end

   if(current_state == 'd0 && cycle == 'd1024)
   begin
      current_state <= next_state;
      cycle <= 'd1;
   end

   if(current_state == 'd1 && cycle == 'd128)
   begin
      current_state <= next_state;
      cycle <= 'd1;
   end

   if(current_state == 'd2 && cycle == 'd128)
   begin
      current_state <= next_state;
      cycle <= 'd1;
   end

   if(current_state == 'd3 && cycle == 'd128)
   begin
      current_state <= next_state;
      cycle <= 'd1;
   end

   if(current_state == 'd4 && cycle == 'd128)
   begin
      current_state <= next_state;
      cycle <= 'd1;
   end

   if(current_state == 'd5 && cycle == 'd512)
   begin
      current_state <= next_state;
      cycle <= 'd1;
   end

   if(current_state == 'd6 && cycle == 'd1024)
   begin
      current_state <= next_state;
      cycle <= 'd1;
   end
end

always@(current_state)
begin
   case(current_state)
      'd0 : next_state <= 'd1;
      'd1 : next_state <= 'd2;
      'd2 : next_state <= 'd3;
      'd3 : next_state <= 'd4;
      'd4 : next_state <= 'd5;
      'd5 : next_state <= 'd6;
      'd6 : next_state <= 'd0;
   endcase
end

endmodule
