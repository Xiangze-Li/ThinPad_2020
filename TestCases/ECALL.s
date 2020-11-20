    li      s0, 30      # Sys Call PUT_CHAR
    li      a0, 0x21
    li      t0, 0x7F
.loop:
    ecall
    addi    a0, a0, 1
    bne     a0, t0, .loop
    ret
