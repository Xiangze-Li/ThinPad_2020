# 读取地址非法: 0x5

    li      t0, 0x70400000
    lw      t1, 0(t0)   # Wrong Load
    ret
