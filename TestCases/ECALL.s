# 系统调用: 正确
# 打印可见 ASCII 字符

    li      s0, 30      # Sys Call PUT_CHAR
    li      a0, 0x21
    li      t0, 0x7F
.loop:
    ecall
    addi    a0, a0, 1
    bne     a0, t0, .loop
    ret
