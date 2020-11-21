
kernel.elf:     file format elf32-littleriscv


Disassembly of section .text:

80000000 <INITLOCATE>:
// 监控程序的入口点，.text.init 段放在内存的 0x80000000 位置，是最先执行的代码。
    .p2align 2
    .section .text.init
INITLOCATE:                         // 定位启动程序
    la s10, START
80000000:	00000d17          	auipc	s10,0x0
80000004:	17cd0d13          	addi	s10,s10,380 # 8000017c <START>
    jr s10
80000008:	000d0067          	jr	s10

8000000c <WRITE_SERIAL>:
    .global READ_SERIAL
    .global READ_SERIAL_WORD
    .global READ_SERIAL_XLEN

WRITE_SERIAL:                       // 写串口：将a0的低八位写入串口
    li t0, COM1
8000000c:	100002b7          	lui	t0,0x10000

80000010 <.TESTW>:
.TESTW:
    lb t1, %lo(COM_LSR_OFFSET)(t0)  // 查看串口状态
80000010:	00528303          	lb	t1,5(t0) # 10000005 <INITLOCATE-0x6ffffffb>
    andi t1, t1, COM_LSR_THRE       // 截取写状态位
80000014:	02037313          	andi	t1,t1,32
    bne t1, zero, .WSERIAL          // 状态位非零可写进入写
80000018:	00031463          	bnez	t1,80000020 <.WSERIAL>
    j .TESTW                        // 检测验证，忙等待
8000001c:	ff5ff06f          	j	80000010 <.TESTW>

80000020 <.WSERIAL>:
.WSERIAL:
    sb a0, %lo(COM_THR_OFFSET)(t0)  // 写入寄存器a0中的值
80000020:	00a28023          	sb	a0,0(t0)
    jr ra
80000024:	00008067          	ret

80000028 <WRITE_SERIAL_WORD>:

WRITE_SERIAL_WORD:
    addi sp, sp, -2*XLEN
80000028:	ff810113          	addi	sp,sp,-8
    STORE ra, 0x0(sp)
8000002c:	00112023          	sw	ra,0(sp)
    STORE s0, XLEN(sp)
80000030:	00812223          	sw	s0,4(sp)

    mv s0, a0
80000034:	00050413          	mv	s0,a0

    andi a0, a0, 0xFF
80000038:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
8000003c:	fd1ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    srli a0, s0, 8
80000040:	00845513          	srli	a0,s0,0x8

    andi a0, a0, 0xFF
80000044:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
80000048:	fc5ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    srli a0, s0, 16
8000004c:	01045513          	srli	a0,s0,0x10

    andi a0, a0, 0xFF
80000050:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
80000054:	fb9ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    srli a0, s0, 24
80000058:	01845513          	srli	a0,s0,0x18

    andi a0, a0, 0xFF
8000005c:	0ff57513          	andi	a0,a0,255
    jal WRITE_SERIAL
80000060:	fadff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    mv a0, s0
80000064:	00040513          	mv	a0,s0

    LOAD ra, 0x0(sp)
80000068:	00012083          	lw	ra,0(sp)
    LOAD s0, XLEN(sp)
8000006c:	00412403          	lw	s0,4(sp)
    addi sp, sp, 2*XLEN
80000070:	00810113          	addi	sp,sp,8

    jr ra
80000074:	00008067          	ret

80000078 <WRITE_SERIAL_XLEN>:

WRITE_SERIAL_XLEN:
    addi sp, sp, -XLEN
80000078:	ffc10113          	addi	sp,sp,-4
    STORE ra, 0x0(sp)
8000007c:	00112023          	sw	ra,0(sp)

    jal WRITE_SERIAL_WORD
80000080:	fa9ff0ef          	jal	ra,80000028 <WRITE_SERIAL_WORD>
#ifdef RV64
    srli a0, a0, 32
    jal WRITE_SERIAL_WORD
#endif
    LOAD ra, 0x0(sp)
80000084:	00012083          	lw	ra,0(sp)
    addi sp, sp, XLEN
80000088:	00410113          	addi	sp,sp,4

    jr ra
8000008c:	00008067          	ret

80000090 <READ_SERIAL>:

READ_SERIAL:                        // 读串口：将读到的数据写入a0低八位
    li t0, COM1
80000090:	100002b7          	lui	t0,0x10000

80000094 <.TESTR>:
.TESTR:
    lb t1, %lo(COM_LSR_OFFSET)(t0)
80000094:	00528303          	lb	t1,5(t0) # 10000005 <INITLOCATE-0x6ffffffb>
    andi t1, t1, COM_LSR_DR         // 截取读状态位
80000098:	00137313          	andi	t1,t1,1
    bne t1, zero, .RSERIAL          // 状态位非零可读进入读
8000009c:	00031463          	bnez	t1,800000a4 <.RSERIAL>
#ifdef ENABLE_INT
    ori v0, zero, SYS_wait          // 取得wait调用号
    syscall SYSCALL_BASE            // 睡眠等待
#endif
*/
    j .TESTR                        // 检测验证
800000a0:	ff5ff06f          	j	80000094 <.TESTR>

800000a4 <.RSERIAL>:
.RSERIAL:
    lb a0, %lo(COM_RBR_OFFSET)(t0)
800000a4:	00028503          	lb	a0,0(t0)
    jr ra
800000a8:	00008067          	ret

800000ac <READ_SERIAL_WORD>:

READ_SERIAL_WORD:
    addi sp, sp, -5*XLEN             // 保存ra,s0-3
800000ac:	fec10113          	addi	sp,sp,-20
    STORE ra, 0x0(sp)
800000b0:	00112023          	sw	ra,0(sp)
    STORE s0, XLEN(sp)
800000b4:	00812223          	sw	s0,4(sp)
    STORE s1, 2*XLEN(sp)
800000b8:	00912423          	sw	s1,8(sp)
    STORE s2, 3*XLEN(sp)
800000bc:	01212623          	sw	s2,12(sp)
    STORE s3, 4*XLEN(sp)
800000c0:	01312823          	sw	s3,16(sp)

    jal READ_SERIAL                 // 读串口获得八个比特
800000c4:	fcdff0ef          	jal	ra,80000090 <READ_SERIAL>
    or s0, zero, a0                 // 结果存入s0
800000c8:	00a06433          	or	s0,zero,a0
    jal READ_SERIAL                 // 读串口获得八个比特
800000cc:	fc5ff0ef          	jal	ra,80000090 <READ_SERIAL>
    or s1, zero, a0                 // 结果存入s1
800000d0:	00a064b3          	or	s1,zero,a0
    jal READ_SERIAL                 // 读串口获得八个比特
800000d4:	fbdff0ef          	jal	ra,80000090 <READ_SERIAL>
    or s2, zero, a0                 // 结果存入s2
800000d8:	00a06933          	or	s2,zero,a0
    jal READ_SERIAL                 // 读串口获得八个比特
800000dc:	fb5ff0ef          	jal	ra,80000090 <READ_SERIAL>
    or s3, zero, a0                 // 结果存入s3
800000e0:	00a069b3          	or	s3,zero,a0

    andi s0, s0, 0x00FF             // 截取低八位
800000e4:	0ff47413          	andi	s0,s0,255
    andi s1, s1, 0x00FF
800000e8:	0ff4f493          	andi	s1,s1,255
    andi s2, s2, 0x00FF
800000ec:	0ff97913          	andi	s2,s2,255
    andi s3, s3, 0x00FF
800000f0:	0ff9f993          	andi	s3,s3,255
    or a0, zero, s3                 // 存高八位
800000f4:	01306533          	or	a0,zero,s3
    sll a0, a0, 8                   // 左移
800000f8:	00851513          	slli	a0,a0,0x8
    or a0, a0, s2                   // 存八位
800000fc:	01256533          	or	a0,a0,s2
    sll a0, a0, 8                   // 左移
80000100:	00851513          	slli	a0,a0,0x8
    or a0, a0, s1                   // 存八位
80000104:	00956533          	or	a0,a0,s1
    sll a0, a0, 8                   // 左移
80000108:	00851513          	slli	a0,a0,0x8
    or a0, a0, s0                   // 存低八位
8000010c:	00856533          	or	a0,a0,s0

    LOAD ra, 0x0(sp)                // 恢复ra,s0
80000110:	00012083          	lw	ra,0(sp)
    LOAD s0, XLEN(sp)
80000114:	00412403          	lw	s0,4(sp)
    LOAD s1, 2*XLEN(sp)
80000118:	00812483          	lw	s1,8(sp)
    LOAD s2, 3*XLEN(sp)
8000011c:	00c12903          	lw	s2,12(sp)
    LOAD s3, 4*XLEN(sp)
80000120:	01012983          	lw	s3,16(sp)
    addi sp, sp, 5*XLEN
80000124:	01410113          	addi	sp,sp,20
    jr ra
80000128:	00008067          	ret

8000012c <READ_SERIAL_XLEN>:

READ_SERIAL_XLEN:
    addi sp, sp, -2*XLEN             // 保存ra,s0-3
8000012c:	ff810113          	addi	sp,sp,-8
    STORE ra, 0x0(sp)
80000130:	00112023          	sw	ra,0(sp)
    STORE s0, XLEN(sp)
80000134:	00812223          	sw	s0,4(sp)

    jal READ_SERIAL_WORD
80000138:	f75ff0ef          	jal	ra,800000ac <READ_SERIAL_WORD>
    mv s0, a0
8000013c:	00050413          	mv	s0,a0
#ifdef RV64
    jal READ_SERIAL_WORD
    sll a0, a0, 32
    add s0, s0, a0
#endif
    mv a0, s0
80000140:	00040513          	mv	a0,s0
    LOAD ra, 0x0(sp)                // 恢复ra,s0
80000144:	00012083          	lw	ra,0(sp)
    LOAD s0, XLEN(sp)
80000148:	00412403          	lw	s0,4(sp)
    addi sp, sp, 2*XLEN
8000014c:	00810113          	addi	sp,sp,8
    jr ra
80000150:	00008067          	ret

80000154 <EXCEPTION_HANDLER>:
    .endr

#else
HALT:
EXCEPTION_HANDLER:
    j HALT
80000154:	0000006f          	j	80000154 <EXCEPTION_HANDLER>

80000158 <FATAL>:
#endif

FATAL:                              // 严重问题，重启
    ori a0, zero, 0x80              // 错误信号
80000158:	08006513          	ori	a0,zero,128
    jal WRITE_SERIAL                // 发送
8000015c:	eb1ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    csrrs a0, mcause, zero
    jal WRITE_SERIAL_XLEN
    csrrs a0, mtval, zero
    jal WRITE_SERIAL_XLEN
#else
    mv a0, zero
80000160:	00000513          	li	a0,0
    jal WRITE_SERIAL_XLEN
80000164:	f15ff0ef          	jal	ra,80000078 <WRITE_SERIAL_XLEN>
    jal WRITE_SERIAL_XLEN
80000168:	f11ff0ef          	jal	ra,80000078 <WRITE_SERIAL_XLEN>
    jal WRITE_SERIAL_XLEN
8000016c:	f0dff0ef          	jal	ra,80000078 <WRITE_SERIAL_XLEN>
#endif

    la a0, START                    // 重启地址
80000170:	00000517          	auipc	a0,0x0
80000174:	00c50513          	addi	a0,a0,12 # 8000017c <START>
    jr a0
80000178:	00050067          	jr	a0

8000017c <START>:
    .p2align 2

    .global START
START:
    // 清空 BSS
    la s10, _sbss
8000017c:	007f0d17          	auipc	s10,0x7f0
80000180:	e84d0d13          	addi	s10,s10,-380 # 807f0000 <_sbss>
    la s11, _ebss
80000184:	007f0d97          	auipc	s11,0x7f0
80000188:	f94d8d93          	addi	s11,s11,-108 # 807f0118 <_ebss>

8000018c <bss_init>:
bss_init:
    beq s10, s11, bss_init_done
8000018c:	01bd0863          	beq	s10,s11,8000019c <bss_init_done>
    sw  zero, 0(s10)
80000190:	000d2023          	sw	zero,0(s10)
    addi s10, s10, 4
80000194:	004d0d13          	addi	s10,s10,4
    j   bss_init
80000198:	ff5ff06f          	j	8000018c <bss_init>

8000019c <bss_init_done>:
    ori s0, s0, 1
    csrw mtvec, s0
mtvec_done:
#endif

    la sp, KERNEL_STACK_INIT         // 设置内核栈
8000019c:	00800117          	auipc	sp,0x800
800001a0:	e6410113          	addi	sp,sp,-412 # 80800000 <KERNEL_STACK_INIT>
    or s0, sp, zero
800001a4:	00016433          	or	s0,sp,zero
    li t0, USER_STACK_INIT          // 设置用户栈
800001a8:	807f02b7          	lui	t0,0x807f0
    // 设置用户态程序的 sp(x2) 和 fp(x8) 寄存器
    la t1, uregs_sp
800001ac:	007f0317          	auipc	t1,0x7f0
800001b0:	e5830313          	addi	t1,t1,-424 # 807f0004 <uregs_sp>
    STORE t0, 0(t1)
800001b4:	00532023          	sw	t0,0(t1)
    la t1, uregs_fp
800001b8:	007f0317          	auipc	t1,0x7f0
800001bc:	e6430313          	addi	t1,t1,-412 # 807f001c <uregs_fp>
    STORE t0, 0(t1)
800001c0:	00532023          	sw	t0,0(t1)
    li t1, COM_IER_RDI
    sb t1, %lo(COM_IER_OFFSET)(t0)
#endif

    // 清空并留出空间用于存储中断帧
    li t0, TF_SIZE
800001c4:	08000293          	li	t0,128
.LC0:
    addi t0, t0, -XLEN
800001c8:	ffc28293          	addi	t0,t0,-4 # 807efffc <KERNEL_STACK_INIT+0xfffefffc>
    addi sp, sp, -XLEN
800001cc:	ffc10113          	addi	sp,sp,-4
    STORE zero, 0(sp)
800001d0:	00012023          	sw	zero,0(sp)
    bne t0, zero, .LC0
800001d4:	fe029ae3          	bnez	t0,800001c8 <bss_init_done+0x2c>

    la t0, TCBT               // 载入TCBT地址
800001d8:	007f0297          	auipc	t0,0x7f0
800001dc:	f2828293          	addi	t0,t0,-216 # 807f0100 <TCBT>
    STORE sp, 0(t0)           // thread0(idle)的中断帧地址设置
800001e0:	0022a023          	sw	sp,0(t0)

    mv t6, sp                 // t6保存idle中断帧位置
800001e4:	00010f93          	mv	t6,sp

    li t0, TF_SIZE
800001e8:	08000293          	li	t0,128
.LC1:
    addi t0, t0, -XLEN              // 滚动计数器
800001ec:	ffc28293          	addi	t0,t0,-4
    addi sp, sp, -XLEN              // 移动栈指针
800001f0:	ffc10113          	addi	sp,sp,-4
    STORE zero, 0(sp)               // 初始化栈空间
800001f4:	00012023          	sw	zero,0(sp)
    bne t0, zero, .LC1              // 初始化循环
800001f8:	fe029ae3          	bnez	t0,800001ec <bss_init_done+0x50>

    la t0, TCBT                     // 载入TCBT地址
800001fc:	007f0297          	auipc	t0,0x7f0
80000200:	f0428293          	addi	t0,t0,-252 # 807f0100 <TCBT>
    STORE sp, XLEN(t0)                    // thread1(shell/user)的中断帧地址设置
80000204:	0022a223          	sw	sp,4(t0)
    STORE sp, TF_sp(t6)                // 设置idle线程栈指针(调试用?)
80000208:	002fa223          	sw	sp,4(t6)

    la t2, TCBT + XLEN
8000020c:	007f0397          	auipc	t2,0x7f0
80000210:	ef838393          	addi	t2,t2,-264 # 807f0104 <TCBT+0x4>
    LOAD t2, 0(t2)                    // 取得thread1的TCB地址
80000214:	0003a383          	lw	t2,0(t2)

#ifdef ENABLE_INT
    csrw mscratch, t2              // 设置当前线程为thread1
#endif

    la t1, current   
80000218:	007f0317          	auipc	t1,0x7f0
8000021c:	ef830313          	addi	t1,t1,-264 # 807f0110 <current>
    sw t2, 0(t1)
80000220:	00732023          	sw	t2,0(t1)
    or t0, t0, t1
    csrw satp, t0
    sfence.vma
#endif

    j WELCOME                       // 进入主线程
80000224:	0040006f          	j	80000228 <WELCOME>

80000228 <WELCOME>:

WELCOME:
    la s1, monitor_version          // 装入启动信息
80000228:	00001497          	auipc	s1,0x1
8000022c:	f2c48493          	addi	s1,s1,-212 # 80001154 <monitor_version>
    lb a0, 0(s1)
80000230:	00048503          	lb	a0,0(s1)
.Loop0:
    addi s1, s1, 0x1
80000234:	00148493          	addi	s1,s1,1
    jal WRITE_SERIAL                // 调用串口写函数
80000238:	dd5ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    lb a0, 0(s1)
8000023c:	00048503          	lb	a0,0(s1)
    bne a0, zero, .Loop0            // 打印循环至0结束符
80000240:	fe051ae3          	bnez	a0,80000234 <WELCOME+0xc>

    j SHELL                         // 开始交互
80000244:	0340006f          	j	80000278 <SHELL>

80000248 <IDLELOOP>:

IDLELOOP:
    nop
80000248:	00000013          	nop
    nop
8000024c:	00000013          	nop
    nop
80000250:	00000013          	nop
    nop
80000254:	00000013          	nop
    nop
80000258:	00000013          	nop
    nop
8000025c:	00000013          	nop
    nop
80000260:	00000013          	nop
    nop
80000264:	00000013          	nop
    nop
80000268:	00000013          	nop
    nop
8000026c:	00000013          	nop
    j IDLELOOP
80000270:	fd9ff06f          	j	80000248 <IDLELOOP>
    nop
80000274:	00000013          	nop

80000278 <SHELL>:
     * 
     *  用户空间寄存器：x1-x31依次保存在0x807F0000连续124字节
     *  用户程序入口临时存储：0x807F0000
     */
SHELL:
    jal READ_SERIAL                  // 读操作符
80000278:	e19ff0ef          	jal	ra,80000090 <READ_SERIAL>

    ori t0, zero, 'R'
8000027c:	05206293          	ori	t0,zero,82
    beq a0, t0, .OP_R
80000280:	06550863          	beq	a0,t0,800002f0 <.OP_R>
    ori t0, zero, 'D'
80000284:	04406293          	ori	t0,zero,68
    beq a0, t0, .OP_D
80000288:	0a550263          	beq	a0,t0,8000032c <.OP_D>
    ori t0, zero, 'A'
8000028c:	04106293          	ori	t0,zero,65
    beq a0, t0, .OP_A
80000290:	0c550e63          	beq	a0,t0,8000036c <.OP_A>
    ori t0, zero, 'G'
80000294:	04706293          	ori	t0,zero,71
    beq a0, t0, .OP_G
80000298:	10550c63          	beq	a0,t0,800003b0 <.OP_G>
    ori t0, zero, 'T'
8000029c:	05406293          	ori	t0,zero,84
    beq a0, t0, .OP_T
800002a0:	00550863          	beq	a0,t0,800002b0 <.OP_T>

    li a0, XLEN                     // 错误的操作符，输出 XLEN，用于区分 RV32 和 RV64
800002a4:	00400513          	li	a0,4
    jal WRITE_SERIAL                 // 把 XLEN 写给 term
800002a8:	d65ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    j .DONE                         
800002ac:	2400006f          	j	800004ec <.DONE>

800002b0 <.OP_T>:

.OP_T:                              // 操作 - 打印页表
    addi sp, sp, -3*XLEN
800002b0:	ff410113          	addi	sp,sp,-12
    STORE s1, 0(sp)
800002b4:	00912023          	sw	s1,0(sp)
    STORE s2, XLEN(sp)
800002b8:	01212223          	sw	s2,4(sp)

#ifdef ENABLE_PAGING
    csrr s1, satp
    slli s1, s1, 12
#else
    li s1, -1
800002bc:	fff00493          	li	s1,-1
#endif
    STORE s1, 2*XLEN(sp)
800002c0:	00912423          	sw	s1,8(sp)
    addi s1, sp, 2*XLEN
800002c4:	00810493          	addi	s1,sp,8
    li s2, XLEN
800002c8:	00400913          	li	s2,4
.LC0:
    lb a0, 0(s1)           // 读取字节
800002cc:	00048503          	lb	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
800002d0:	fff90913          	addi	s2,s2,-1
    jal WRITE_SERIAL                 // 写入串口
800002d4:	d39ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    addi s1, s1, 0x1                // 移动打印指针
800002d8:	00148493          	addi	s1,s1,1
    bne s2, zero, .LC0              // 打印循环
800002dc:	fe0918e3          	bnez	s2,800002cc <.OP_T+0x1c>

    LOAD s1, 0x0(sp)
800002e0:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
800002e4:	00412903          	lw	s2,4(sp)
    addi sp, sp, 3*XLEN
800002e8:	00c10113          	addi	sp,sp,12

    j .DONE
800002ec:	2000006f          	j	800004ec <.DONE>

800002f0 <.OP_R>:

.OP_R:                              // 操作 - 打印用户空间寄存器
    addi sp, sp, -2*XLEN                 // 保存s1,s2
800002f0:	ff810113          	addi	sp,sp,-8
    STORE s1, 0(sp)
800002f4:	00912023          	sw	s1,0(sp)
    STORE s2, XLEN(sp)
800002f8:	01212223          	sw	s2,4(sp)

    la s1, uregs
800002fc:	007f0497          	auipc	s1,0x7f0
80000300:	d0448493          	addi	s1,s1,-764 # 807f0000 <_sbss>
    ori s2, zero, 31*XLEN               // 计数器，打印 31 个寄存器
80000304:	07c06913          	ori	s2,zero,124
.LC1:
    lb a0, 0(s1)           // 读取字节
80000308:	00048503          	lb	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
8000030c:	fff90913          	addi	s2,s2,-1
    jal WRITE_SERIAL                 // 写入串口
80000310:	cfdff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    addi s1, s1, 0x1                // 移动打印指针
80000314:	00148493          	addi	s1,s1,1
    bne s2, zero, .LC1              // 打印循环
80000318:	fe0918e3          	bnez	s2,80000308 <.OP_R+0x18>

    LOAD s1, 0(sp)                    // 恢复s1,s2
8000031c:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
80000320:	00412903          	lw	s2,4(sp)
    addi sp, sp, 2*XLEN
80000324:	00810113          	addi	sp,sp,8
    j .DONE
80000328:	1c40006f          	j	800004ec <.DONE>

8000032c <.OP_D>:

.OP_D:                              // 操作 - 打印内存num字节
    addi sp, sp, -2*XLEN                 // 保存s1,s2
8000032c:	ff810113          	addi	sp,sp,-8
    STORE s1, 0(sp)
80000330:	00912023          	sw	s1,0(sp)
    STORE s2, XLEN(sp)
80000334:	01212223          	sw	s2,4(sp)

    jal READ_SERIAL_XLEN
80000338:	df5ff0ef          	jal	ra,8000012c <READ_SERIAL_XLEN>
    or s1, a0, zero                 // 获得addr
8000033c:	000564b3          	or	s1,a0,zero
    jal READ_SERIAL_XLEN
80000340:	dedff0ef          	jal	ra,8000012c <READ_SERIAL_XLEN>
    or s2, a0, zero                 // 获得num
80000344:	00056933          	or	s2,a0,zero

.LC2:
    lb a0, 0(s1)                    // 读取字节
80000348:	00048503          	lb	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
8000034c:	fff90913          	addi	s2,s2,-1
    jal WRITE_SERIAL                 // 写入串口
80000350:	cbdff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    addi s1, s1, 0x1                // 移动打印指针
80000354:	00148493          	addi	s1,s1,1
    bne s2, zero, .LC2              // 打印循环
80000358:	fe0918e3          	bnez	s2,80000348 <.OP_D+0x1c>

    LOAD s1, 0(sp)                    // 恢复s1,s2
8000035c:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
80000360:	00412903          	lw	s2,4(sp)
    addi sp, sp, 2*XLEN
80000364:	00810113          	addi	sp,sp,8
    j .DONE
80000368:	1840006f          	j	800004ec <.DONE>

8000036c <.OP_A>:

.OP_A:                              // 操作 - 写入内存num字节，num为4的倍数
    addi sp, sp, -2*XLEN                 // 保存s1,s2
8000036c:	ff810113          	addi	sp,sp,-8
    STORE s1, 0(sp)
80000370:	00912023          	sw	s1,0(sp)
    STORE s2, 4(sp)
80000374:	01212223          	sw	s2,4(sp)

    jal READ_SERIAL_XLEN
80000378:	db5ff0ef          	jal	ra,8000012c <READ_SERIAL_XLEN>
    or s1, a0, zero                 // 获得addr
8000037c:	000564b3          	or	s1,a0,zero
    jal READ_SERIAL_XLEN
80000380:	dadff0ef          	jal	ra,8000012c <READ_SERIAL_XLEN>
    or s2, a0, zero                 // 获得num
80000384:	00056933          	or	s2,a0,zero
    srl s2, s2, 2                   // num除4，获得字数
80000388:	00295913          	srli	s2,s2,0x2
.LC3:                               // 每次写入一字
    jal READ_SERIAL_WORD              // 从串口读入一字
8000038c:	d21ff0ef          	jal	ra,800000ac <READ_SERIAL_WORD>
    sw a0, 0(s1)                    // 写内存一字
80000390:	00a4a023          	sw	a0,0(s1)
    addi s2, s2, -1                 // 滚动计数器
80000394:	fff90913          	addi	s2,s2,-1
    addi s1, s1, 4                  // 移动写指针
80000398:	00448493          	addi	s1,s1,4
    bne s2, zero, .LC3              // 写循环
8000039c:	fe0918e3          	bnez	s2,8000038c <.OP_A+0x20>

#ifdef ENABLE_FENCEI
    fence.i                         // 有 Cache 时让写入的代码生效
#endif

    LOAD s1, 0(sp)                    // 恢复s1,s2
800003a0:	00012483          	lw	s1,0(sp)
    LOAD s2, XLEN(sp)
800003a4:	00412903          	lw	s2,4(sp)
    addi sp, sp, 2*XLEN
800003a8:	00810113          	addi	sp,sp,8
    j .DONE
800003ac:	1400006f          	j	800004ec <.DONE>

800003b0 <.OP_G>:

.OP_G:
    jal READ_SERIAL_XLEN            // 获取addr
800003b0:	d7dff0ef          	jal	ra,8000012c <READ_SERIAL_XLEN>
    mv s10, a0                      // 保存到 s10
800003b4:	00050d13          	mv	s10,a0

    ori a0, zero, TIMERSET          // 写TIMERSET(0x06)信号
800003b8:	00606513          	ori	a0,zero,6
    jal WRITE_SERIAL                 // 告诉终端用户程序开始运行
800003bc:	c51ff0ef          	jal	ra,8000000c <WRITE_SERIAL>
    csrw mepc, s10                // 用户程序入口写入EPC
    li a0, MSTATUS_MPP_MASK
    csrc mstatus, a0     // 设置 MPP=0 ，对应 U-mode
#endif

    la ra, uregs              // 定位用户空间寄存器备份地址
800003c0:	007f0097          	auipc	ra,0x7f0
800003c4:	c4008093          	addi	ra,ra,-960 # 807f0000 <_sbss>
    STORE sp, TF_ksp(ra)           // 保存栈指针
800003c8:	0820a023          	sw	sp,128(ra)

    // LOAD x1,  TF_ra(ra)
    LOAD sp, TF_sp(ra)
800003cc:	0040a103          	lw	sp,4(ra)
    LOAD gp, TF_gp(ra)
800003d0:	0080a183          	lw	gp,8(ra)
    LOAD tp, TF_tp(ra)
800003d4:	00c0a203          	lw	tp,12(ra)
    LOAD t0, TF_t0(ra)
800003d8:	0100a283          	lw	t0,16(ra)
    LOAD t1, TF_t1(ra)
800003dc:	0140a303          	lw	t1,20(ra)
    LOAD t2, TF_t2(ra)
800003e0:	0180a383          	lw	t2,24(ra)
    LOAD s0, TF_s0(ra)
800003e4:	01c0a403          	lw	s0,28(ra)
    LOAD s1, TF_s1(ra)
800003e8:	0200a483          	lw	s1,32(ra)
    LOAD a0, TF_a0(ra)
800003ec:	0240a503          	lw	a0,36(ra)
    LOAD a1, TF_a1(ra)
800003f0:	0280a583          	lw	a1,40(ra)
    LOAD a2, TF_a2(ra)
800003f4:	02c0a603          	lw	a2,44(ra)
    LOAD a3, TF_a3(ra)
800003f8:	0300a683          	lw	a3,48(ra)
    LOAD a4, TF_a4(ra)
800003fc:	0340a703          	lw	a4,52(ra)
    LOAD a5, TF_a5(ra)
80000400:	0380a783          	lw	a5,56(ra)
    LOAD a6, TF_a6(ra)
80000404:	03c0a803          	lw	a6,60(ra)
    LOAD a7, TF_a7(ra)
80000408:	0400a883          	lw	a7,64(ra)
    LOAD s2, TF_s2(ra)
8000040c:	0440a903          	lw	s2,68(ra)
    LOAD s3, TF_s3(ra)
80000410:	0480a983          	lw	s3,72(ra)
    LOAD s4, TF_s4(ra)
80000414:	04c0aa03          	lw	s4,76(ra)
    LOAD s5, TF_s5(ra)
80000418:	0500aa83          	lw	s5,80(ra)
    LOAD s6, TF_s6(ra)
8000041c:	0540ab03          	lw	s6,84(ra)
    LOAD s7, TF_s7(ra)
80000420:	0580ab83          	lw	s7,88(ra)
    LOAD s8, TF_s8(ra)
80000424:	05c0ac03          	lw	s8,92(ra)
    LOAD s9, TF_s9(ra)
80000428:	0600ac83          	lw	s9,96(ra)
    // LOAD s10, TF_s10(ra)
    LOAD s11, TF_s11(ra)
8000042c:	0680ad83          	lw	s11,104(ra)
    LOAD t3, TF_t3(ra)
80000430:	06c0ae03          	lw	t3,108(ra)
    LOAD t4, TF_t4(ra)
80000434:	0700ae83          	lw	t4,112(ra)
    LOAD t5, TF_t5(ra)
80000438:	0740af03          	lw	t5,116(ra)
    LOAD t6, TF_t6(ra)
8000043c:	0780af83          	lw	t6,120(ra)

80000440 <.ENTER_UESR>:
.ENTER_UESR:
#ifdef ENABLE_INT
    la ra, .USERRET_USER                // ra写入返回地址
    mret                                // 进入用户程序
#else
    la ra, .USERRET2                    // ra写入返回地址
80000440:	00000097          	auipc	ra,0x0
80000444:	00c08093          	addi	ra,ra,12 # 8000044c <.USERRET2>
    jr s10
80000448:	000d0067          	jr	s10

8000044c <.USERRET2>:

    j .DONE
#endif

.USERRET2:
    la ra, uregs              // 定位用户空间寄存器备份地址
8000044c:	007f0097          	auipc	ra,0x7f0
80000450:	bb408093          	addi	ra,ra,-1100 # 807f0000 <_sbss>

    //STORE ra, TF_ra(ra)
    STORE sp, TF_sp(ra)
80000454:	0020a223          	sw	sp,4(ra)
    STORE gp, TF_gp(ra)
80000458:	0030a423          	sw	gp,8(ra)
    STORE tp, TF_tp(ra)
8000045c:	0040a623          	sw	tp,12(ra)
    STORE t0, TF_t0(ra)
80000460:	0050a823          	sw	t0,16(ra)
    STORE t1, TF_t1(ra)
80000464:	0060aa23          	sw	t1,20(ra)
    STORE t2, TF_t2(ra)
80000468:	0070ac23          	sw	t2,24(ra)
    STORE s0, TF_s0(ra)
8000046c:	0080ae23          	sw	s0,28(ra)
    STORE s1, TF_s1(ra)
80000470:	0290a023          	sw	s1,32(ra)
    STORE a0, TF_a0(ra)
80000474:	02a0a223          	sw	a0,36(ra)
    STORE a1, TF_a1(ra)
80000478:	02b0a423          	sw	a1,40(ra)
    STORE a2, TF_a2(ra)
8000047c:	02c0a623          	sw	a2,44(ra)
    STORE a3, TF_a3(ra)
80000480:	02d0a823          	sw	a3,48(ra)
    STORE a4, TF_a4(ra)
80000484:	02e0aa23          	sw	a4,52(ra)
    STORE a5, TF_a5(ra)
80000488:	02f0ac23          	sw	a5,56(ra)
    STORE a6, TF_a6(ra)
8000048c:	0300ae23          	sw	a6,60(ra)
    STORE a7, TF_a7(ra)
80000490:	0510a023          	sw	a7,64(ra)
    STORE s2, TF_s2(ra)
80000494:	0520a223          	sw	s2,68(ra)
    STORE s3, TF_s3(ra)
80000498:	0530a423          	sw	s3,72(ra)
    STORE s4, TF_s4(ra)
8000049c:	0540a623          	sw	s4,76(ra)
    STORE s5, TF_s5(ra)
800004a0:	0550a823          	sw	s5,80(ra)
    STORE s6, TF_s6(ra)
800004a4:	0560aa23          	sw	s6,84(ra)
    STORE s7, TF_s7(ra)
800004a8:	0570ac23          	sw	s7,88(ra)
    STORE s8, TF_s8(ra)
800004ac:	0580ae23          	sw	s8,92(ra)
    STORE s9, TF_s9(ra)
800004b0:	0790a023          	sw	s9,96(ra)
    STORE s10, TF_s10(ra)
800004b4:	07a0a223          	sw	s10,100(ra)
    STORE s11, TF_s11(ra)
800004b8:	07b0a423          	sw	s11,104(ra)
    STORE t3, TF_t3(ra)
800004bc:	07c0a623          	sw	t3,108(ra)
    STORE t4, TF_t4(ra)
800004c0:	07d0a823          	sw	t4,112(ra)
    STORE t5, TF_t5(ra)
800004c4:	07e0aa23          	sw	t5,116(ra)
    STORE t6, TF_t6(ra)
800004c8:	07f0ac23          	sw	t6,120(ra)

    LOAD sp, TF_ksp(ra)             // 重新获得当前监控程序栈顶指针
800004cc:	0800a103          	lw	sp,128(ra)
    mv a0, ra
800004d0:	00008513          	mv	a0,ra
    la ra, .USERRET2
800004d4:	00000097          	auipc	ra,0x0
800004d8:	f7808093          	addi	ra,ra,-136 # 8000044c <.USERRET2>
    STORE ra, TF_ra(a0)
800004dc:	00152023          	sw	ra,0(a0)

    ori a0, zero, TIMETOKEN         // 发送TIMETOKEN(0x07)信号
800004e0:	00706513          	ori	a0,zero,7
    jal WRITE_SERIAL                // 告诉终端用户程序结束运行
800004e4:	b29ff0ef          	jal	ra,8000000c <WRITE_SERIAL>

    j .DONE
800004e8:	0040006f          	j	800004ec <.DONE>

800004ec <.DONE>:

.DONE:
    j SHELL                         // 交互循环
800004ec:	d8dff06f          	j	80000278 <SHELL>
	...

80001000 <UTEST_SIMPLE>:
    //.set noat
    .section .text.utest
    .p2align 2

UTEST_SIMPLE:
    addi t5, t5, 0x1
80001000:	001f0f13          	addi	t5,t5,1
    jr ra
80001004:	00008067          	ret

80001008 <UTEST_1PTB>:
     *  这段程序一般没有数据冲突和结构冲突，可作为性能标定。
     *  若执行延迟槽，执行这段程序需至少384M指令，384M/time可算得频率。
     *  不执行延迟槽，执行这段程序需至少320M指令，320M/time可算得频率。
     */
UTEST_1PTB:
    li t0, TESTLOOP64         // 装入64M
80001008:	040002b7          	lui	t0,0x4000
.LC0:
    addi t0, t0, -1                // 滚动计数器
8000100c:	fff28293          	addi	t0,t0,-1 # 3ffffff <INITLOCATE-0x7c000001>
    ori t1, zero, 0
80001010:	00006313          	ori	t1,zero,0
    ori t2, zero, 1
80001014:	00106393          	ori	t2,zero,1
    ori t3, zero, 2
80001018:	00206e13          	ori	t3,zero,2
    bne t0, zero, .LC0
8000101c:	fe0298e3          	bnez	t0,8000100c <UTEST_1PTB+0x4>
    jr ra
80001020:	00008067          	ret

80001024 <UTEST_2DCT>:
     *  这段程序含有大量数据冲突，可测试数据冲突对效率的影响。
     *  执行延迟槽，执行这段程序需至少192M指令。
     *  不执行延迟槽，执行这段程序需至少176M指令。
     */
UTEST_2DCT:
    lui t0, %hi(TESTLOOP16)         // 装入16M
80001024:	010002b7          	lui	t0,0x1000
    ori t1, zero, 1
80001028:	00106313          	ori	t1,zero,1
    ori t2, zero, 2
8000102c:	00206393          	ori	t2,zero,2
    ori t3, zero, 3
80001030:	00306e13          	ori	t3,zero,3
.LC1:
    xor t2, t2, t1                  // 交换t1,t2
80001034:	0063c3b3          	xor	t2,t2,t1
    xor t1, t1, t2
80001038:	00734333          	xor	t1,t1,t2
    xor t2, t2, t1
8000103c:	0063c3b3          	xor	t2,t2,t1
    xor t3, t3, t2                  // 交换t2,t3
80001040:	007e4e33          	xor	t3,t3,t2
    xor t2, t2, t3
80001044:	01c3c3b3          	xor	t2,t2,t3
    xor t3, t3, t2
80001048:	007e4e33          	xor	t3,t3,t2
    xor t1, t1, t3                  // 交换t3,t1
8000104c:	01c34333          	xor	t1,t1,t3
    xor t3, t3, t1
80001050:	006e4e33          	xor	t3,t3,t1
    xor t1, t1, t3
80001054:	01c34333          	xor	t1,t1,t3
    addi t0, t0, -1
80001058:	fff28293          	addi	t0,t0,-1 # ffffff <INITLOCATE-0x7f000001>
    bne t0, zero, .LC1
8000105c:	fc029ce3          	bnez	t0,80001034 <UTEST_2DCT+0x10>
    jr ra
80001060:	00008067          	ret

80001064 <UTEST_3CCT>:
     *  这段程序有大量控制冲突。
     *  无延迟槽执行需要至少256M指令；
     *  有延迟槽需要224M指令。
     */
UTEST_3CCT:
    lui t0, %hi(TESTLOOP64)         // 装入64M
80001064:	040002b7          	lui	t0,0x4000
.LC2_0:
    bne t0, zero, .LC2_1
80001068:	00029463          	bnez	t0,80001070 <UTEST_3CCT+0xc>
    jr ra
8000106c:	00008067          	ret
.LC2_1:
    j .LC2_2
80001070:	0040006f          	j	80001074 <UTEST_3CCT+0x10>
.LC2_2:
    addi t0, t0, -1
80001074:	fff28293          	addi	t0,t0,-1 # 3ffffff <INITLOCATE-0x7c000001>
    j .LC2_0
80001078:	ff1ff06f          	j	80001068 <UTEST_3CCT+0x4>
    addi t0, t0, -1
8000107c:	fff28293          	addi	t0,t0,-1

80001080 <UTEST_4MDCT>:
     *  这段程序反复对内存进行有数据冲突的读写。
     *  不执行延迟槽需要至少192M指令。
     *  执行延迟槽，需要至少224M指令。
     */
UTEST_4MDCT:
    lui t0, %hi(TESTLOOP32)          // 装入32M
80001080:	020002b7          	lui	t0,0x2000
    addi sp, sp, -4
80001084:	ffc10113          	addi	sp,sp,-4
.LC3:
    sw t0, 0(sp)
80001088:	00512023          	sw	t0,0(sp)
    lw t1, 0(sp)
8000108c:	00012303          	lw	t1,0(sp)
    addi t1, t1, -1
80001090:	fff30313          	addi	t1,t1,-1
    sw t1, 0(sp)
80001094:	00612023          	sw	t1,0(sp)
    lw t0, 0(sp)
80001098:	00012283          	lw	t0,0(sp)
    bne t0, zero, .LC3
8000109c:	fe0296e3          	bnez	t0,80001088 <UTEST_4MDCT+0x8>
    addi sp, sp, 4
800010a0:	00410113          	addi	sp,sp,4
    jr ra
800010a4:	00008067          	ret

800010a8 <UTEST_CRYPTONIGHT>:
    ecall
    jr ra
#endif

UTEST_CRYPTONIGHT:
    li a0, 0x80400000 // base addr
800010a8:	80400537          	lui	a0,0x80400
    li a1, 0x200000 // 2M bytes
800010ac:	002005b7          	lui	a1,0x200
    li a3, 524288 // number of iterations
800010b0:	000806b7          	lui	a3,0x80
    li a4, 0x1FFFFC // 2M mask
800010b4:	00200737          	lui	a4,0x200
800010b8:	ffc70713          	addi	a4,a4,-4 # 1ffffc <INITLOCATE-0x7fe00004>
    add a1, a1, a0 // end addr
800010bc:	00a585b3          	add	a1,a1,a0
    li s0, 1 // rand number
800010c0:	00100413          	li	s0,1

    mv a2, a0
800010c4:	00050613          	mv	a2,a0

800010c8 <.INIT_LOOP>:
.INIT_LOOP:
    sw s0, 0(a2)
800010c8:	00862023          	sw	s0,0(a2)

    // xorshift lfsr
    slli s1, s0, 13
800010cc:	00d41493          	slli	s1,s0,0xd
    xor s0, s0, s1
800010d0:	00944433          	xor	s0,s0,s1
    srli s1, s0, 17
800010d4:	01145493          	srli	s1,s0,0x11
    xor s0, s0, s1
800010d8:	00944433          	xor	s0,s0,s1
    slli s1, s0, 5
800010dc:	00541493          	slli	s1,s0,0x5
    xor s0, s0, s1
800010e0:	00944433          	xor	s0,s0,s1

    addi a2, a2, 4
800010e4:	00460613          	addi	a2,a2,4
    bne a2, a1, .INIT_LOOP
800010e8:	feb610e3          	bne	a2,a1,800010c8 <.INIT_LOOP>

    li a2, 0
800010ec:	00000613          	li	a2,0
    li t0, 0
800010f0:	00000293          	li	t0,0

800010f4 <.MAIN_LOOP>:
.MAIN_LOOP:
    // calculate a valid addr from rand number
    and t0, s0, a4
800010f4:	00e472b3          	and	t0,s0,a4
    add t0, a0, t0
800010f8:	005502b3          	add	t0,a0,t0
    // read from it
    lw t0, 0(t0)
800010fc:	0002a283          	lw	t0,0(t0) # 2000000 <INITLOCATE-0x7e000000>
    // xor with last iteration's t0
    xor t0, t0, t1
80001100:	0062c2b3          	xor	t0,t0,t1
    // xor rand number with current t0
    xor s0, s0, t0
80001104:	00544433          	xor	s0,s0,t0

    // get new rand number from xorshift lfsr
    slli s1, s0, 13
80001108:	00d41493          	slli	s1,s0,0xd
    xor s0, s0, s1
8000110c:	00944433          	xor	s0,s0,s1
    srli s1, s0, 17
80001110:	01145493          	srli	s1,s0,0x11
    xor s0, s0, s1
80001114:	00944433          	xor	s0,s0,s1
    slli s1, s0, 5
80001118:	00541493          	slli	s1,s0,0x5
    xor s0, s0, s1
8000111c:	00944433          	xor	s0,s0,s1

    // calculate a valid addr from new rand number
    and t1, s0, a4
80001120:	00e47333          	and	t1,s0,a4
    add t1, a0, t1
80001124:	00650333          	add	t1,a0,t1
    // write t0 to this addr
    sw t0, 0(t1)
80001128:	00532023          	sw	t0,0(t1)
    // save t0 for next iteration
    mv t1, t0
8000112c:	00028313          	mv	t1,t0

    // get new rand number from xorshift lfsr
    slli s1, s0, 13
80001130:	00d41493          	slli	s1,s0,0xd
    xor s0, s0, s1
80001134:	00944433          	xor	s0,s0,s1
    srli s1, s0, 17
80001138:	01145493          	srli	s1,s0,0x11
    xor s0, s0, s1
8000113c:	00944433          	xor	s0,s0,s1
    slli s1, s0, 5
80001140:	00541493          	slli	s1,s0,0x5
    xor s0, s0, s1
80001144:	00944433          	xor	s0,s0,s1

    add a2, a2, 1
80001148:	00160613          	addi	a2,a2,1
    bne a2, a3, .MAIN_LOOP
8000114c:	fad614e3          	bne	a2,a3,800010f4 <.MAIN_LOOP>

    jr ra
80001150:	00008067          	ret
