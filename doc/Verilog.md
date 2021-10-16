# Verilog

Running on FPGA Board

SOPC: System-on-a-Programmable-Chip



## 编译

从左到右编译，因此右边引用左边

```
iverilog 1.v 2.v ...
```



当然如果你 include 了就不用重复编译了



对于 CPU，`testbench.v -> riscv_top.v -> cpu.v`

因此可以参考的一个编译指令是

```bash
iverilog cpu.v riscv_top.v hci.v common/*/*.v ../sim/testbench.v -o ../out/a.out
```



## 波形图

在 `testbench.v` 中加入如下语句

```verilog
initial begin            
    $dumpfile("wave.vcd");        //生成的vcd文件名称
    $dumpvars(0, led_demo_tb);    //tb模块名称
end
```



`vvp a.out`  即可



##  编译指令

`  宏定义

```
`define AddrLen 8
`define InstLen 8
```

例：

```
`AddrLen
`InstLen
```



```
`include
```



```
`timescale
```



## 连续赋值

`wire`  描述的是物理上的线网，因此只能被赋值一次（连线）

```verilog
assign LHS = RHS; 

// LHS 必须是 wire 类型
// RHS 类型没有要求
// RHS 有事件发送 会重新计算 RHS 并赋值给 LHS

wire A, B;
wire Cout = A & B; // 初始化赋值
```



## 时延

```verilog
assign #10 Z = A & B;

// A & B 计算完成后 10ns 赋值给 Z


// sim 中时延
initial begin
        ai        = 0 ;
        #25 ;      ai        = 1 ;
        #35 ;      ai        = 0 ;        //60ns
        #40 ;      ai        = 1 ;        //100ns
        #10 ;      ai        = 0 ;        //110ns
end
```



## 过程结构语句

`begin`  `end`  相当于大括号

```verilog
initial begin
	// 顺序执行, 只执行一次
end
```



```verilog
always begin
	// 重复执行
end  

always @ (posedge clk) begin
	// 上升沿触发
end    
```



**过程赋值** （寄存器、整数、实数）

- 阻塞赋值  `=`
- 非阻塞赋值 `<=`



## 系统函数



`$stop`   暂停仿真

`$readmemh`   读取数据

`$time`  显示仿真时间

`$display`  显示信号值

`$signed`  符号  



## 设计



每个部件是一个 `module`

输入一般都要有：

```verilog
input wire clk // clock signal
input wire rst // reset signal
```

