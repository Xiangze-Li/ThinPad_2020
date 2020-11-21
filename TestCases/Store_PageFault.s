# 页表: 向不可写区间写
# 应当有 mcause == 0xF

    li      t0, 0x00000004
    li      a0, 0x3
    sw      a0, 0(t0)
    lw      a1, 0(t0)
    ret
