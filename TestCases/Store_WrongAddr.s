    li      t0, 0x70400000
    li      t1, 0x00000555
    sw      t1, 0(t0)   # Wrong Store
    ret
