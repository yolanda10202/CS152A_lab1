`timescale 1ns / 1ps

module model_uart(/*AUTOARG*/
   // Outputs
   TX,
   // Inputs
   RX
   );

   output TX;
   input  RX;

   parameter baud    = 115200;
   parameter bittime = 1000000000/baud;
   parameter name    = "UART0";
   
   reg [7:0] rxData;
   // buff will store the 4 numbers we want
   // e.g. if we want to print "0003\n", buff will store 0x0003
   reg [31:0] buff;
   // count will keep track of how many numbers we currently added
   reg [2:0] count;
   
   event     evBit;
   event     evByte;
   event     evTxBit;
   event     evTxByte;
   reg       TX;

   initial
     begin
        TX = 1'b1;
        buff = 32'b00000000000000000000000000000000;
        count = 3'b000;
     end
   
   always @ (negedge RX)
     begin
        rxData[7:0] = 8'h0;
        #(0.5*bittime);
        repeat (8)
          begin
             #bittime ->evBit;
             //rxData[7:0] = {rxData[6:0],RX};
             rxData[7:0] = {RX,rxData[7:1]};
          end
        ->evByte;
        
		  if ((rxData[7:0] == 10 || rxData[7:0] == 13) && (buff != 0))
        begin
		     //$display("rxData: %s", rxData);
           $display ("%d %s Received bytes:(%s%s%s%s)", $stime, name, 
                      buff[31:24], buff[23:16], buff[15:8], buff[7:0]);
           count <= 0;
           buff <= 0;
        end
		  else
		  begin
			  // updating buff so that it contains the new data in [7:0]
			  // shift left by 8 so we can use the 8 lsb bits to store new data
			  buff <= buff << 8;
			  // place the new data to the 8 lsb bits
			  buff[7:0] <= rxData[7:0];
			  count <= count + 1;
			  
			  
			  
			  // if we have filled the buff, we print and reset 
			  /*
			  if (count == 3'b100)
			  begin
					$display ("%d %s Received bytes:(%s%s%s%s)", $stime, name, 
								 buff[31:24], buff[23:16], buff[15:8], buff[7:0]);
					$display("hello2\n");
					count <= 0;
			  end
			  */
		  end
     end

   task tskRxData;
      output [7:0] data;
      begin
         @(evByte);
         data = rxData;
      end
   endtask // for
      
   task tskTxData;
      input [7:0] data;
      reg [9:0]   tmp;
      integer     i;
      begin
         tmp = {1'b1, data[7:0], 1'b0};
         for (i=0;i<10;i=i+1)
           begin
              TX = tmp[i];
              #bittime;
              ->evTxBit;
           end
         ->evTxByte;
      end
   endtask // tskTxData
   
endmodule // model_uart
