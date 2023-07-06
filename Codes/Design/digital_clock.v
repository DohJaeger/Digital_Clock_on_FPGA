`timescale 1ns / 1ps

module digital_clock(
    input clk,
    input CENT_BTN,UP_BTN, LEFT_BTN, RIGHT_BTN, DOWN_BTN, SET_CLK_SWITCH, ALARM_SWITCH, 
          ALARM_ON, STOP_WATCH_SWITCH, STOP_WATCH_ON,
    output [6:0] CATHODE, output [3:0] ANODE,
    output reg [0:0] ALARM_LED,
    output reg [0:0] SET_CLK_LED,
    output reg [0:0] SET_STOPWATCH_LED,
    output reg [5:0] Hours
);

reg [31:0] counter,Set_Clock_Counter;
reg [5:0] Minutes,Seconds = 0;       //showclock & set clock

parameter Show_Clock = 2'b00;  
parameter Set_Alarm = 2'b01;    
parameter Set_Stopwatch = 2'b10;

reg Current_Mode = Show_Clock;
reg current_bit = 0;
reg [3:0] Val_0,Val_1, Val_2, Val_3 = 0;

reg [5:0] Lap_Seconds [4:0], Lap_Mini_Seconds [4:0];
reg [1:0] lap_counter1, lap_counter2 =0;    
reg Up_Btn_State = 0;

    //Mode Change
    always@(posedge CENT_BTN) begin
        case(Current_Mode)
            Show_Clock : Current_Mode <= Set_Alarm;
            Set_Alarm : Current_Mode <= Show_Clock; 
            //Set_Stopwatch : Current_Mode <= Show_Clock; 
            default : Current_Mode <= Show_Clock;
        endcase
        SET_STOPWATCH_LED <= ~SET_STOPWATCH_LED;
    end

    //Stopwatch
    reg [6:0] Mini_Seconds = 0;
    reg [5:0] Seconds_Stopwatch = 0;
    reg [30:0] stopwatch_counter = 0;
    always@(posedge clk) begin
        if(STOP_WATCH_ON && STOP_WATCH_SWITCH) begin
            if(stopwatch_counter < 1_000_000)
                stopwatch_counter <= stopwatch_counter + 1;
            else begin
                stopwatch_counter <= 0;
                if(Mini_Seconds < 99) begin
                    Mini_Seconds <= Mini_Seconds + 1;
                end
                else begin
                    Mini_Seconds <= 0;
                    Seconds_Stopwatch <= Seconds_Stopwatch + 1;
                end
            end
        end
        if(!STOP_WATCH_SWITCH) begin
            Mini_Seconds <= 0;
            Seconds_Stopwatch <= 0;
        end
    end


    //Alarm Set
    reg [31:0] blink_counter,alarm_counter;
    reg [5:0] alarm_h,alarm_m = 1;
    reg current_bit_alarm = 0;
    
    always@(posedge clk) begin
        if(ALARM_SWITCH) begin
        if(blink_counter < 10_000_000) begin
            blink_counter <= blink_counter + 1;
        end
        else
            begin
            blink_counter <= 0;
            case (current_bit_alarm)
                1'b0: begin 
                    if (UP_BTN) begin
                        if(alarm_m == 59)
                            alarm_m <= 0;
                        else
                            alarm_m <= alarm_m + 1;
                    end
                    if (DOWN_BTN) begin 
                        if (alarm_m > 0)
                            alarm_m <= alarm_m - 1;
                        else 
                            alarm_m <= 59;
                    end
                    if (LEFT_BTN || RIGHT_BTN) begin
                        current_bit_alarm <= 1;
                    end
                end
                1'b1: begin 
                    if (UP_BTN)
                        begin 
                        if(alarm_h < 23)
                            alarm_h <= alarm_h + 1;
                        else
                            alarm_h <= 0;
                              
                        end
                    if (DOWN_BTN)
                        begin 
                        if (alarm_h > 0)
                            alarm_h <= alarm_h - 1;
                        else
                            alarm_h <= 23;
                        end
                     if (RIGHT_BTN || LEFT_BTN) 
                         begin 
                         current_bit_alarm <= 0;
                         end
                      end                      
             endcase          
            end                
        end
    end
    
    //Alarm Blink
    always@(posedge clk) begin
        if(Hours == alarm_h && Minutes == alarm_m && ALARM_ON) begin
            if (alarm_counter < 100000000) begin 
                alarm_counter <= alarm_counter + 1;
            end 
            else begin
                alarm_counter <= 0;
                ALARM_LED <= ~ ALARM_LED;
            end
        end
        else
            ALARM_LED <= 0;
    end
    
    
    //Clock and Set Clock
    always@(posedge clk) begin
        if(!SET_CLK_SWITCH) begin     
            if (counter < 100000000) begin 
                counter <= counter + 1;
            end 
            else begin
                counter <= 0;
                Seconds <= Seconds + 1;
            end     
            if (Seconds >= 60) begin 
                Seconds <= 0;
                Minutes <= Minutes + 1;
            end
            if (Minutes >= 60) begin 
                Minutes <= 0;
                Hours <= Hours + 1;
            end
            if (Hours >= 24) begin 
                Hours <= 0;
            end
        end
        
        else begin
            SET_CLK_LED <= SET_CLK_SWITCH;           
               if (Set_Clock_Counter < (25000000)) begin
                   Set_Clock_Counter <= Set_Clock_Counter + 1;
               end 
               else begin
               Set_Clock_Counter <= 0;
               case (current_bit)
                   1'b0: begin
                       if (UP_BTN)
                           begin
                            if(Minutes < 59)
                                Minutes <= Minutes + 1;
                            else
                                Minutes <= 0;
                           end
                       if (DOWN_BTN)
                           begin 
                           if (Minutes > 0) begin
                               Minutes <= Minutes - 1;
                           end 
                           if(Minutes == 0) begin
                               Minutes <= 59;
                           end
                           end
                       if (LEFT_BTN || RIGHT_BTN)
                           begin
                           current_bit <= 1;
                           end
                       end
                   1'b1: begin 
                       if (UP_BTN)
                          begin 
                          if(Hours < 23)
                            Hours <= Hours + 1;
                          if(Hours == 23)
                            Hours <= 0;
                          end
                       if (DOWN_BTN)
                           begin 
                           if (Hours > 0)
                               begin
                               Hours <= Hours - 1;
                               end
                           else if (Hours == 0)
                               begin
                               Hours <= 23;
                               //AM_PM <= ~AM_PM;
                               end
                           end
                       if (RIGHT_BTN || LEFT_BTN)
                           begin 
                           current_bit <= 0;
                           end
                       end                      
                   endcase          
               end                  
           end 
    end      
   
   
   //Seven Segment Display 
   sevseg display(.clk(clk),     
       .binary_input_0(Val_0),
       .binary_input_1(Val_1),
       .binary_input_2(Val_2),
       .binary_input_3(Val_3),
       .ANODE(ANODE),
       .CATHODE(CATHODE));
           
    //Clock Display
    always@(posedge clk) begin
        if(STOP_WATCH_SWITCH) begin
            Val_0 <= Mini_Seconds % 10;
            Val_1 <= Mini_Seconds / 10;
            Val_2 <= Seconds_Stopwatch % 10;
            Val_3 <= Seconds_Stopwatch / 10;
        end
        
        else if(ALARM_SWITCH) begin
            Val_0 <= alarm_m % 10;
            Val_1 <= alarm_m / 10;
            Val_2 <= alarm_h % 10;
            Val_3 <= alarm_h / 10;
        end 
        else if(Current_Mode == Show_Clock | SET_CLK_SWITCH) begin
            Val_2 <= Minutes % 10;
            Val_3 <= Minutes / 10;
            Val_0 <= Seconds % 10;
            Val_1 <= Seconds / 10;
        end
    end
        
endmodule