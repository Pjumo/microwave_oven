`timescale 1ns / 1ps

module btn_debouncer(
    input clk,
    input [4:0] btn,
    output [4:0] debounced_btn
);
    debouncer U_debouncer_btnU (
        .clk(clk),
        .noisy_btn(btn[0]),
        .clean_btn(debounced_btn[0])
    );

    debouncer U_debouncer_btnL (
        .clk(clk),
        .noisy_btn(btn[1]),
        .clean_btn(debounced_btn[1])
    );

    debouncer U_debouncer_btnC (
        .clk(clk),
        .noisy_btn(btn[2]),
        .clean_btn(debounced_btn[2])
    );

    debouncer U_debouncer_btnR (
        .clk(clk),
        .noisy_btn(btn[3]),
        .clean_btn(debounced_btn[3])
    );

    debouncer U_debouncer_btnD (
        .clk(clk),
        .noisy_btn(btn[4]),
        .clean_btn(debounced_btn[4])
    );

endmodule

module debouncer (
  input clk,
  input noisy_btn,
  output reg clean_btn = 0
);
    reg [19:0] count = 0;
    reg btn_state = 0;

    always @(posedge clk) begin
        if (noisy_btn == btn_state) begin // 상태가 유지되면 카운트 초기화
            count <= 0;
        end else begin
            count <= count + 1;
            if (count >= 1_000_000) begin // 10ms 동안 동일한 상태가 유지되면
                btn_state <= noisy_btn; // 안정된 상태로 인정하고 값 갱신
                clean_btn <= noisy_btn;
                count <= 0;
            end
        end
    end
endmodule
