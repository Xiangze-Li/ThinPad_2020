# 页表: 读取地址未对齐
# 查表过程不会受到影响, 应有 mcause == 0x4

    li      t0, 0x7FC10004
    lw      t1, 1(t0)
    ret
