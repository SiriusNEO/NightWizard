# CPU

时序逻辑：always @(posedge clk)，全用非阻塞赋值

组合逻辑：always @(*)，全用阻塞赋值



总之时序逻辑的引用值都是上一个 clk 的值，组合逻辑是这一个周期

波形图中值改变代表其赋值为，不论时序还是组合！



信号 ena/flag：

由发起人当前周期发起，持续一个clk，下一个周期接受者会收到（收到上一个周期为 TRUE 的信号）。此时发起人一般会关掉，防止重复操作。



## Fetcher

两个信号口，一个接 memctrl，一个接 dispatcher

周期1：fetcher 空闲，向 memctrl 发起请求

周期8：fetcher 拿到 ok 信号，将指令传给 decoder，给 dsp 发 ok 信号，

​			给 dsp 传 pc 值

## MemCtrl

### Fetcher

周期2：memctrl 接受请求，进入 busy 状态。

​			读第一个数（下一个周期才传回结果），同时把 counter 置为 0。

周期3（cnt=0）：memctrl 仍处于请求状态，

​			读第二个数，同时把 counter = 1

周期4（cnt=1）：读第三个数，

​							**把第一个数放入输出**，counter = 2

周期5（cnt=2）：读第四个数，把第二个数放入输出，counter = 3

周期6（cnt=3）：把第三个数放入输出，counter = 4

周期7（cnt=4）：把第四个数放入输出，传回 ok 信号，置为 IDLE



![1](assets\1.png)



### Store

周期18：memctrl 接受请求，进入 busy 状态。

​			 不写数，同时把 counter 置为 1。

周期19（cnt=1）：写第一个数（这是为了统一），cnt+1

周期20（cnt=2）:  写第二个数，cnt+1

周期21（cnt=3）：写第三个数，cnt+1

周期22（cnt=4）：写第四个数，传回 ok 信号，置为 IDLE。



### Load

周期14：memctrl 接受请求，busy。

​			读第一个数（下一个周期才传回结果），同时把 counter 置为 0。

周期15（cnt=0）：memctrl 仍处于请求状态，

​			读第二个数，同时把 counter = 1

周期16（cnt=1）：读第三个数，

​							**把第一个数放入输出**，counter = 2

周期17（cnt=2）：读第四个数，把第二个数放入输出，counter = 3

周期18（cnt=3）：把第三个数放入输出，counter = 4

周期19（cnt=4）：把第四个数放入输出，传回 ok 信号，置为 IDLE



## Decoder

**组合逻辑。**

周期8：decoder 拿到指令，立即解码出结果。传给 dsp。

​			这些结果一直保留到下次解码（8~15保留）。

![2](C:\Users\17138\Desktop\CPU\NightWizard\doc\assets\2.png)

**8个周期为一次解码单位周期。**

## Dispatcher

周期9：dispatcher 拿到 pc、openum 等等，以及 if 的 ok_flag

​			dispatcher 访问有关数据（rob 是否 ready，取 rs 的值）

​			dispatcher 分配到 rob

周期10：分配，issue 到 rs 或者 lsb，以及 reg

​			 dsp 到 rs 亮灯



## RS

free_index 与 exec_index 用一个组合逻辑计算

周期11：rs 接到分配，进行插入

周期12：发射掉刚刚插入的指令



## RS_EX

组合逻辑。

周期12：接收到指令，直接进行计算，发送到 cdb



## LSB

周期11：ls 接到分配，进行插入

周期12：ls 查看队首：

- 如果是 store，发送给 rob，store_rob_id，直接 make it ready
- 如果是 load，发送给 ls_ex 准备 load



周期15：接收到 commit，更新

周期16：发送给 ls_ex——进行 store，同时弹出队首。



## LS_EX

时序电路。

### Store

周期17：接收到 lsb 信息，通知 memctrl store

周期23：接收到 ok 信号，写回完成。

### Load

周期13：接收到 LSB 的请求，通知 memctrl load

周期20：ls_ex 拿到 ok 信号，说明 load 结束，load 出来的值发送到 cdb



## ROB

周期10（与 dsp）：ROB 接收到 dsp 请求，分配位置。



### RS

周期13：ROB 接收到 cdb 信息，进行更新。ready 标记为 true。

周期14：commit 掉。发送全局 commit 消息。



### STORE

周期13：ROB 接收到 store_rob_id，调成 ready

周期14：commit 掉。发送全局 commit。



### LOAD

周期21：ls执行完毕，刷新，ready=true

周期22：commit 掉。



## REG

周期11：reg 接到 dispatcher 的分配申请。分配一个位置。

周期15：接收到 commit 消息，更新 reg。

