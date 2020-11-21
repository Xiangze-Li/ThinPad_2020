# 页表: 从未映射区间取指
# 应该有 mcause == 0xC

    li      t0, 0x80400000
    jr      t0
