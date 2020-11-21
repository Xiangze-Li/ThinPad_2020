# 错误系统调用编号
# 什么也不发生

    li      s0, 31      # WRONG Sys Call
    li      a0, 0x21
    li      t0, 0x7F
.loop:
    ecall
    addi    a0, a0, 1
    bne     a0, t0, .loop
    ret
