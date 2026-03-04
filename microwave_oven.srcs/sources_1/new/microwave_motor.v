`timescale 1ns / 1ps

module microwave_motor(
    input clk,
    input reset,
    input door_state,     // 0: 닫힘 1: 열림
    input microwave_state,
    output reg SERVO_PWM_OUT,
    output PWM_OUT,
    output [1:0] in1_in2
);

    // 50Hz -> 20ms
    localparam PERIOD = 22'd2_000_000;

    localparam CLOSE_PULSE = 22'd100_000;  // 1ms -> 0도
    localparam OPEN_PULSE  = 22'd200_000;  // 2ms -> 180도

    reg [21:0] counter = 0;
    wire [21:0] pulse_width;
    reg [3:0] r_counter_PWM;

    assign pulse_width = (door_state) ? OPEN_PULSE : CLOSE_PULSE;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            counter <= 0;
            SERVO_PWM_OUT <= 0;
        end else begin
            if(counter < PERIOD - 1)
                counter <= counter + 1;
            else
                counter <= 0;

            if(counter < pulse_width)
                SERVO_PWM_OUT <= 1;
            else
                SERVO_PWM_OUT <= 0;
        end
    end

    // 10MHz PWM 신호 생성 (0~9)
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_counter_PWM <= 0;
        end else begin
            if(r_counter_PWM >= 4'd9)
                r_counter_PWM <= 0;
            else
                r_counter_PWM <= r_counter_PWM + 1;
        end
    end

    assign PWM_OUT = (r_counter_PWM < 4'd9) ? 1'b1 : 1'b0;
    assign in1_in2 = microwave_state ? 2'b10 : 2'b11;

endmodule