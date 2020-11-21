# 页表: 读取未映射空间
# 应当有 mcause == 0xD

    li t0, 0x10000000
    lb a1, 0(t0)
    ret
