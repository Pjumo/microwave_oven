`timescale 1ns / 1ps

module microwave_beep(
    input clk,
    input reset,
    input btn_power,       // 전원 ON/OFF
    input btn_10s,       // 10초 증가
    input btn_door,       // 문 Open/Close
    input btn_30s,       // 30초 증가
    input btn_cancel,       // 취소
    input time_out,   // 전자레인지 종료
    output led,
    output reg buzzer,
    output door_state,
    output power_state
);

    localparam DO       = 22'd191_113;
    localparam RE       = 22'd170_262; 
    localparam MI       = 22'd151_686; 
    localparam FA       = 22'd143_173;
    localparam SOL      = 22'd127_553;
    localparam LA       = 22'd113_636;
    localparam SI       = 22'd101_239; 
    localparam HIGH_DO  = 22'd95_556; 
    localparam HIGH_RE  = 22'd85_131; 
    
    localparam BEEP = 22'd95_556;  // 버튼 Beep
    localparam BEEP_TIME_OUT = 22'd25_000;  // time_out Beep

    localparam TIME_BEEP  = 27'd10_000_000;  // 100ms
    localparam TIME_1SEC  = 27'd100_000_000; // 1초 대기
    localparam TIME_NOTE  = 27'd20_000_000;  // 200ms

    // edge 검출
    reg prev_btn_power, prev_btn_10s, prev_btn_door, prev_btn_30s, prev_btn_cancel;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            prev_btn_power <= 0; prev_btn_10s <= 0; 
            prev_btn_door <= 0; prev_btn_30s <= 0; 
            prev_btn_cancel <= 0;
        end else begin
            prev_btn_power <= btn_power; prev_btn_10s <= btn_10s; 
            prev_btn_door <= btn_door; prev_btn_30s <= btn_30s; 
            prev_btn_cancel <= btn_cancel;
        end
    end

    wire btn_power_state = btn_power & ~prev_btn_power;
    wire btn_10s_state = btn_10s & ~prev_btn_10s;
    wire btn_door_state = btn_door & ~prev_btn_door;
    wire btn_30s_state = btn_30s & ~prev_btn_30s;
    wire btn_cancel_state = btn_cancel & ~prev_btn_cancel;

    localparam IDLE         = 2'd0;
    localparam BEEP_PLAY    = 2'd1;
    localparam S1_TIMER      = 2'd2;
    localparam MELODY_PLAY  = 2'd3;

    reg [1:0]  play_step;  
    reg [1:0]  melody_type; 
    reg        r_power_state;
    reg        r_door_state;
    
    reg [26:0] play_timer; 
    reg [4:0]  note_step; 
    reg [21:0] clk_cnt;    
    
    reg [21:0] step_freq;     
    reg [4:0]  max_note_step; 


    // 멜로디
    always @(*) begin
        step_freq = 0;
        max_note_step = 0;
        case(melody_type)
            1: begin // 전원 ON
                max_note_step = 3;
                case(note_step)
                    0: step_freq = SOL;     
                    1: step_freq = MI;      
                    2: step_freq = HIGH_DO;
                    default: step_freq = 0;
                endcase
            end
            2: begin // 전원 OFF
                max_note_step = 26;
                case(note_step)
                    0: step_freq = SOL;      1: step_freq = HIGH_DO;  2: step_freq = SI;
                    3: step_freq = LA;       4: step_freq = SOL;      5: step_freq = MI;
                    6: step_freq = FA;       7: step_freq = SOL;      8: step_freq = LA;
                    9: step_freq = RE;      10: step_freq = MI;      11: step_freq = FA;
                   12: step_freq = MI;      13: step_freq = SOL;     14: step_freq = SOL;
                   15: step_freq = HIGH_DO; 16: step_freq = SI;      17: step_freq = LA;
                   18: step_freq = SOL;     19: step_freq = HIGH_DO; 20: step_freq = HIGH_RE;
                   21: step_freq = HIGH_DO; 22: step_freq = SI;      23: step_freq = LA;
                   24: step_freq = SI;      25: step_freq = HIGH_DO;
                   default: step_freq = 0;
                endcase
            end
            3: begin // DOOR OPEN
                max_note_step = 3;
                case(note_step)
                    0: step_freq = DO;       1: step_freq = RE;       2: step_freq = MI;
                    default: step_freq = 0;
                endcase
            end
            default: max_note_step = 0;
        endcase
    end

    // 메인
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            play_step <= IDLE;
            r_power_state <= 0;
            r_door_state <= 0;
            melody_type <= 0;
            play_timer <= 0;
            note_step <= 0;
            buzzer <= 0;
            clk_cnt <= 0;
        end else begin
            if(time_out) begin
                if(clk_cnt >= BEEP_TIME_OUT -1) begin
                    clk_cnt <= 0;
                    buzzer <= ~buzzer;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end else begin
                case(play_step)
                    IDLE: begin
                        buzzer <= 0;
                        play_timer <= 0;
                        note_step <= 0;
                        clk_cnt <= 0;
                        
                        if(btn_power_state) begin
                            r_power_state <= ~r_power_state;
                            melody_type <= (~r_power_state) ? 1 : 2;
                            play_step <= BEEP_PLAY;
                        end 
                        else if(btn_door_state) begin
                            r_door_state <= ~r_door_state;
                            melody_type <= 3;
                            play_step <= BEEP_PLAY;
                        end 
                        else if(btn_10s_state || btn_30s_state || btn_cancel_state) begin
                            melody_type <= 0;
                            play_step <= BEEP_PLAY;
                        end
                    end

                    BEEP_PLAY: begin
                        if(play_timer < TIME_BEEP) begin
                            play_timer <= play_timer + 1;
                            if(clk_cnt >= BEEP - 1) begin
                                clk_cnt <= 0;
                                buzzer <= ~buzzer;
                            end else begin
                                clk_cnt <= clk_cnt + 1;
                            end
                        end else begin
                            play_timer <= 0;
                            clk_cnt <= 0;
                            buzzer <= 0; 
                            
                            if(melody_type != 0) play_step <= S1_TIMER;
                            else play_step <= IDLE;
                        end
                    end

                    S1_TIMER: begin
                        buzzer <= 0; 
                        if(play_timer < TIME_1SEC) begin
                            play_timer <= play_timer + 1;
                        end else begin
                            play_timer <= 0;
                            note_step <= 0;
                            play_step <= MELODY_PLAY;
                        end
                    end

                    MELODY_PLAY: begin
                        if(play_timer < TIME_NOTE) begin
                            play_timer <= play_timer + 1;
                            
                            if(play_timer > TIME_NOTE || step_freq == 0) begin
                                buzzer <= 0;
                            end else begin
                                if(clk_cnt >= step_freq - 1) begin
                                    clk_cnt <= 0;
                                    buzzer <= ~buzzer;
                                end else begin
                                    clk_cnt <= clk_cnt + 1;
                                end
                            end
                        end else begin
                            play_timer <= 0;
                            note_step <= note_step + 1;
                            
                            if(note_step >= max_note_step - 1) begin
                                play_step <= IDLE;
                            end
                        end
                    end
                endcase
            end
        end
    end

    assign led = r_power_state;
    assign power_state = r_power_state;
    assign door_state = r_door_state;

endmodule