    li      t0, 0x80400001
    li      t1, 0x00000555
    sw      t1, 0(t0)   # Misaligned Store
    ret
