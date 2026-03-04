`timescale 1ns / 1ps

module microwave_time(
    input clk,
    input reset,
    input btn_10s,
    input btn_30s,
    input btn_cancel,
    input door_state,
    input power_state,
    output [13:0] in_data,
    output reg time_out,
    output reg microwave_state
);
    reg [5:0] minute = 0, second = 0;
    reg prev_btn_10s, prev_btn_30s, prev_btn_cancel;

    reg [$clog2(100_000_000) : 0] cnt_1s;
    reg [$clog2(50_000_000) : 0] cnt_500ms;
    reg [2:0] time_out_cnt = 3'd7;  // time_out_cnt를 초기상태 3'b111로

    always @(posedge clk, posedge reset) begin
        if(reset || !power_state) begin
            minute <= 0;
            second <= 0;
            cnt_1s <= 0;
        end else begin
            if(btn_10s && !prev_btn_10s) begin  // 10초 증가 버튼 눌렸을 때
                if(second >= 50) begin
                    minute <= minute + 1;
                    second <= second - 50;
                end else begin
                    second <= second + 10;
                end
            end else if(btn_30s && !prev_btn_30s) begin  // 30초 증가 버튼 눌렸을 때
                if(second >= 30) begin
                    minute <= minute + 1;
                    second <= second - 30;
                end else begin
                    second <= second + 30;
                end
            end else if(btn_cancel && !prev_btn_cancel) begin  // 취소 버튼 눌렸을 때
                minute <= 0;
                second <= 0;
            end

            if(!door_state) begin    // 문 열려있으면 시간 감소 x
                if(cnt_1s >= 100_000_000) begin // 1초마다 minute, second 감소 로직
                    if(second > 0) begin
                        second <= second - 1;
                    end else if(second == 0 && minute > 0) begin
                        minute <= minute -1;
                        second <= 59;
                    end
                    cnt_1s <= 0;
                end else begin
                    cnt_1s <= cnt_1s + 1;
                end
            end
            prev_btn_10s <= btn_10s;
            prev_btn_30s <= btn_30s;
            prev_btn_cancel <= btn_cancel;
        end
    end

    // time_out logic
    always @(posedge clk, posedge reset) begin
        if(reset || !power_state) begin
            time_out <= 0;
            time_out_cnt <= 3'd7;
        end else begin
            // 시간 버튼 click 시 time_out_cnt를 0으로
            if((btn_10s && !prev_btn_10s) || (btn_30s && !prev_btn_30s)) begin
                time_out_cnt <= 0;
            end
            // 취소 버튼 click 시 time_out 출력 안되게 7로 초기화
            if((btn_cancel && !prev_btn_cancel)) begin
                time_out_cnt <= 3'd7;
            end

            if(time_out_cnt < 6) begin  // 6보다 아래일때만 time_out 비프음, fnd0000 출력용
                if(second == 0 && minute == 0) begin
                    if(cnt_500ms >= 50_000_000) begin
                        time_out <= ~time_out;
                        time_out_cnt <= time_out_cnt + 1;   // 6번 진행 후 time_out = 0
                        cnt_500ms <= 0;
                    end else begin
                        cnt_500ms <= cnt_500ms + 1;
                    end
                end
            end
        end
    end

    // microwave 동작중 확인 로직
    always @(posedge clk, posedge reset) begin
        if(reset || !power_state) begin
            microwave_state <= 0;
        end else begin
            if(door_state) begin
                microwave_state <= 0;
            end else begin
                if(second > 0 || minute > 0) begin
                    microwave_state <= 1;
                end else begin
                    microwave_state <= 0;
                end
            end
        end
    end

    assign in_data = minute * 100 + second;
endmodule
