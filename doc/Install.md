# 配环境之旅



## install riscv-gnu-toolchain

这个东西很大！有约 `10GB`

单纯 `git clone` 很可能会超时，建议使用镜像站 etc.

```
qemu

riscv-binutils
riscv-gdb
// 这俩文件内容一样，赋值粘贴即可
// riscv-binutils-gdb

riscv-dejagnu
riscv-gcc
riscv-glibc
riscv-newlib
```



安装按照 `README.md` 即可，时间要等很久

`sudo make`  



注意我的版本是 `10.2` 如果出现 `cannot find -lgcc`  请修改 `build_test.sh` 版本号





## vscode

天灭 vscode 

多文件 `iverilog`  编译语法高亮太恶心了

将就着写吧（