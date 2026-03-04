`timescale 1ns / 1ps

module microwave_oven(
    input clk,
    input reset,
    input btnU,
    input btnL,
    input btnC,
    input btnR,
    input btnD,
    output buzzer,
    output PWM_OUT,
    output SERVO_PWM_OUT,
    output [1:0] in1_in2,
    output led,
    output [7:0] seg,
    output [3:0] an
);
    wire w_btn_door, w_btn_30s, w_btn_10s, w_btn_power, w_btn_cancel;
    wire w_time_out, w_door_state, w_power_state, w_microwave_state;
    wire [13:0] w_in_data;

    btn_debouncer u_btn_debouncer(
        .clk            (clk),
        .btn            ({btnU, btnL, btnC, btnR, btnD}),
        .debounced_btn  ({w_btn_power, w_btn_10s, w_btn_door, w_btn_30s, w_btn_cancel})
    );

    microwave_time u_microwave_time(
        .clk            (clk),
        .reset          (reset),
        .btn_10s        (w_btn_10s),
        .btn_30s        (w_btn_30s),
        .btn_cancel     (w_btn_cancel),
        .door_state     (w_door_state),
        .power_state    (w_power_state),
        .in_data        (w_in_data),
        .time_out       (w_time_out),
        .microwave_state(w_microwave_state)
    );
    
    microwave_beep u_microwave_beep(
        .clk        (clk),
        .reset      (reset),
        .btn_10s    (w_btn_10s),
        .btn_30s    (w_btn_30s),
        .btn_cancel (w_btn_cancel),
        .btn_door   (w_btn_door),
        .btn_power  (w_btn_power),
        .time_out   (w_time_out),
        .led        (led),
        .buzzer     (buzzer),
        .door_state (w_door_state),
        .power_state(w_power_state)
    );

    microwave_motor u_microwave_motor(
        .clk            (clk),
        .reset          (reset),
        .door_state     (w_door_state),
        .microwave_state(w_microwave_state),
        .SERVO_PWM_OUT  (SERVO_PWM_OUT),
        .PWM_OUT        (PWM_OUT),
        .in1_in2        (in1_in2)
    );

    fnd_controller u_fnd_controller(
        .clk        (clk),
        .reset      (reset),
        .time_out   (w_time_out),
        .door_state (w_door_state),
        .in_data    (w_in_data),
        .seg        (seg),
        .an         (an)
    );
endmodule
