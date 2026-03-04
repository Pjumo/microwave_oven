`timescale 1ns / 1ps

module fnd_controller(
    input clk,
    input reset,
    input time_out,
    input door_state,
    input [13:0] in_data,
    output [3:0] an,
    output [7:0] seg
);
    wire [1:0] w_sel;
    wire [3:0] w_d1, w_d10, w_d100, w_d1000;
    wire w_circle_on;

    fnd_circle_on u_fnd_circle_on(
        .clk    (clk),
        .reset  (reset),
        .circle_on (w_circle_on)
    );

    fnd_digit_select u_fnd_digit_select(
        .clk   (clk),
        .reset (reset),
        .sel   (w_sel)
    );

    bin2bdc4digit u_bin2bdc4digit(
        .in_data    (in_data),
        .clk        (clk),
        .circle_on  (w_circle_on),
        .door_state (door_state),
        .time_out   (time_out),
        .d1         (w_d1),
        .d10        (w_d10),
        .d100       (w_d100),
        .d1000      (w_d1000)
    );

    fnd_digit_display u_fnd_digit_display(
        .digit_sel  (w_sel),
        .d1         (w_d1),
        .d10        (w_d10),
        .d100       (w_d100),
        .d1000      (w_d1000),
        .an         (an),
        .seg        (seg)
    );

endmodule

// circle 동작 보여줄 주기 설정
module fnd_circle_on(
    input clk,
    input reset,
    output reg circle_on    // 0 -> 분초, 1 -> circle
);
    reg [$clog2(130_000_000):0] counter_1s = 0;   // 1.3s

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter_1s <= 0;
            circle_on <= 0;
        end else begin
            if(counter_1s == 130_000_000 -1) begin
                counter_1s <= 0;
                circle_on <= ~circle_on;
            end else begin
                counter_1s <= counter_1s + 1;
            end
        end
    end
endmodule

module fnd_digit_select(
    input clk,
    input reset,
    output reg [1:0] sel    // 00 01 10 11 : 1ms마다 바뀜
);
    reg[$clog2(100_000):0] r_1ms_counter = 0;

    always @(posedge reset, posedge clk) begin
        if(reset) begin
            r_1ms_counter <= 0;
            sel <= 0;
        end else begin
            if(r_1ms_counter == 100_000 - 1) begin
                r_1ms_counter <= 0;
                sel <= sel + 1;
            end else begin
                r_1ms_counter <= r_1ms_counter + 1;
            end
        end
    end
endmodule


module bin2bdc4digit(
    input [13:0] in_data,
    input clk,
    input circle_on,
    input door_state,
    input time_out,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100,
    output [3:0] d1000
);
    parameter NONE_DATA = 14'b000000000000000000;   // in_data의 모든 비트가 0일 경우 아무것도 출력 x
    parameter NONE = 4'd15; // 아무것도 출력하지 않는 fnd data

    reg [$clog2(10_000_000):0] clk_count;
    reg [3:0] circle_count;

    reg [3:0] circle_d1;
    reg [3:0] circle_d10;
    reg [3:0] circle_d100;
    reg [3:0] circle_d1000;

    // 100ms 마다 circle 돌기
    always @(posedge clk) begin
        if(clk_count >= 10_000_000) begin
            clk_count <= 0;
            if(circle_count == 9) begin
                circle_count <= 0;
            end else begin
                circle_count <= circle_count + 1;
            end
        end else begin
            clk_count <= clk_count + 1;
        end
    end

    always @(circle_count) begin
        case(circle_count)
            4'd0: begin
                circle_d1000 <= 4'd10;
                circle_d100 <= NONE;
                circle_d10 <= NONE;
                circle_d1 <= NONE;
            end 
            4'd1: begin
                circle_d1000 <= NONE;
                circle_d100 <= 4'd10;
                circle_d10 <= NONE;
                circle_d1 <= NONE;
            end 
            4'd2: begin
                circle_d1000 <= NONE;
                circle_d100 <= NONE;
                circle_d10 <= 4'd10;
                circle_d1 <= NONE;
            end 
            4'd3: begin
                circle_d1000 <= NONE;
                circle_d100 <= NONE;
                circle_d10 <= NONE;
                circle_d1 <= 4'd10;
            end 
            4'd4: begin
                circle_d1000 <= NONE;
                circle_d100 <= NONE;
                circle_d10 <= NONE;
                circle_d1 <= 4'd11;
            end 
            4'd5: begin
                circle_d1000 <= NONE;
                circle_d100 <= NONE;
                circle_d10 <= NONE;
                circle_d1 <= 4'd12;
            end 
            4'd6: begin
                circle_d1000 <= NONE;
                circle_d100 <= NONE;
                circle_d10 <= 4'd12;
                circle_d1 <= NONE;
            end 
            4'd7: begin
                circle_d1000 <= NONE;
                circle_d100 <= 4'd12;
                circle_d10 <= NONE;
                circle_d1 <= NONE;
            end 
            4'd8: begin
                circle_d1000 <= 4'd12;
                circle_d100 <= NONE;
                circle_d10 <= NONE;
                circle_d1 <= NONE;
            end 
            4'd9: begin
                circle_d1000 <= 4'd13;
                circle_d100 <= NONE;
                circle_d10 <= NONE;
                circle_d1 <= NONE;
            end
            default: begin
                circle_d1000 <= NONE;
                circle_d100 <= NONE;
                circle_d10 <= NONE;
                circle_d1 <= NONE;
            end
        endcase
    end

    // in_data가 NONE_DATA일 경우 아무것도 출력 x, circle_on 여부에 따라 circle 혹은 분초
    assign d1 = (time_out)? 4'd0 : 
                (in_data == NONE_DATA)? NONE : 
                ((circle_on && !door_state) ? circle_d1 : in_data % 10);
    assign d10 = (time_out)? 4'd0 : 
                (in_data == NONE_DATA)? NONE : 
                ((circle_on && !door_state) ? circle_d10 : (in_data / 10) % 10);
    assign d100 = (time_out)? 4'd0 : 
                (in_data == NONE_DATA)? NONE : 
                ((circle_on && !door_state) ? circle_d100 : (in_data / 100) % 10);
    assign d1000 = (time_out)? 4'd0 :
                (in_data == NONE_DATA)? NONE :
                ((circle_on && !door_state) ? circle_d1000 : (in_data / 1000) % 10);
endmodule

module fnd_digit_display(
    input [1:0] digit_sel,
    input [3:0] d1,
    input [3:0] d10,
    input [3:0] d100,
    input [3:0] d1000,
    output reg [3:0] an,
    output reg [7:0] seg
);
    reg [3:0] bcd_data;
    reg dot;    // 분.초를 위한 dot

    always @(digit_sel) begin
        case(digit_sel) 
            2'b00: begin
                dot = 0;
                bcd_data = d1;
                an = 4'b1110;
            end
            2'b01: begin
                dot = 0;
                bcd_data = d10;
                an = 4'b1101;
            end
            2'b10: begin
                dot = 1;
                bcd_data = d100;
                an = 4'b1011;
            end
            2'b11: begin
                dot = 0;
                bcd_data = d1000;
                an = 4'b0111;
            end
            default: begin
                dot = 0;
                bcd_data = 0;
                an = 4'b1111;
            end
        endcase
    end

    always @(bcd_data) begin
        case(bcd_data)
            4'd0: seg = 8'b11000000;
            4'd1: seg = 8'b11111001;
            4'd2: seg = 8'b10100100;
            4'd3: seg = 8'b10110000;
            4'd4: seg = 8'b10011001;
            4'd5: seg = 8'b10010010;
            4'd6: seg = 8'b10000010;
            4'd7: seg = 8'b11111000;
            4'd8: seg = 8'b10000000;
            4'd9: seg = 8'b10010000;
            4'd10: seg = 8'b11111110;   // circle 위쪽 출력
            4'd11: seg = 8'b11111001;   // circle 오른쪽
            4'd12: seg = 8'b11110111;   // circle 아래쪽
            4'd13: seg = 8'b11001111;   // circle 왼쪽
            default: seg = 8'b11111111; // NONE
        endcase

        // bcd_data가 0~9를 나타낼때만 dot이 찍히도록
        if(dot && bcd_data <= 4'd9) begin   // circle 동작 중에는 dot이 찍히지 않게 설정
            seg[7] = 0;
        end
    end
endmodule