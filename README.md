# 计算机组成原理 2020 ThinPad #

实现一个基于简化的 RISC-V 指令系统的 32 位多周期 CPU。

该 CPU 具有以下功能:

1.  执行来自 RV32I 的 19 条基本指令,运行基础版本的监控程序;
2.  执行来自 RV32B 的 3 条扩展指令;
3.  检测并处理异常,执行 CSRRW、ECALL、MRET 等 6 条指令,运行中断和异常版
本的监控程序;
4.  对用户态的内存空间做分页映射,运行页表版本的监控程序。

详见[我们的实验报告](./Report.pdf)。

### NOTE ###

为了简洁起见，删除了`Kernels`文件夹。
