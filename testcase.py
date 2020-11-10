#=# oj.resources.kernel_bin = https://thinpad-oj-1255566273.cos.ap-beijing.myqcloud.com/supervisor-rv/v1.12/rv32/kernel-rv32-no16550.bin

from TestcaseBase import *
import random
import traceback
import enum
import time
import struct
import binascii
import base64
from timeit import default_timer as timer

MAX_RUN_TIME = 5000


class Testcase(TestcaseBase):
    class State(enum.Enum):
        WaitBoot = enum.auto()
        GetXlen = enum.auto()
        RunA = enum.auto()
        RunD = enum.auto()
        RunG = enum.auto()
        WaitG = enum.auto()
        RunR = enum.auto()
        RunD2 = enum.auto()
        Done = enum.auto()

    bootMessage = b'MONITOR for RISC-V - initialized.'
    recvBuf = b''

    @staticmethod
    def int2bytes(val):
        return struct.pack('<I', val)

    @staticmethod
    def bytes2int(val):
        return struct.unpack('<I', val)[0]

    def endTest(self):
        score = 0
        if self.state == self.State.WaitBoot:
            score = 0
        if self.state == self.State.GetXlen:
            score = 0.2
        elif self.state == self.State.RunD:
            score = 0.3
        elif self.state in [self.State.RunG, self.State.WaitG]:
            score = 0.5
        elif self.state == self.State.RunR:
            score = 0.7
        elif self.state == self.State.RunD2:
            score = 0.8
        elif self.state == self.State.Done:
            score = 1

        self.finish(score)
        return True

    def stateChange(self, received: bytes):
        addr = 0x80100000
        if self.state == self.State.WaitBoot:
            bootMsgLen = len(self.bootMessage)
            self.log(f"Boot message: {str(self.recvBuf)[1:]}")
            if received != self.bootMessage:
                self.log('ERROR: incorrect message')
                return self.endTest()
            elif len(self.recvBuf) > bootMsgLen:
                self.log('WARNING: extra bytes received')
            self.recvBuf = b''

            self.state = self.State.GetXlen
            Serial << b'W'
            self.recvBuf = b''
            self.expectedLen = 1

        elif self.state == self.State.GetXlen:
            xlen = received[0]
            if xlen == 4:
                self.log('INFO: running in 32bit, xlen = 4')
                self.recvBuf = b''

                self.state = self.State.RunA
                for i in range(0, len(USER_PROGRAM), 4):
                    Serial << b'A'
                    Serial << self.int2bytes(addr+i)
                    Serial << self.int2bytes(4)
                    Serial << USER_PROGRAM[i:i+4]
                self.log("User program written")

                self.state = self.State.RunD
                self.expectedLen = len(USER_PROGRAM)
                Serial << b'D'
                Serial << self.int2bytes(addr)
                Serial << self.int2bytes(len(USER_PROGRAM))
            elif xlen == 8:
                self.log('INFO: running in 64bit, xlen = 8')
                self.log('ERROR: rv64 is unsupported on online judge')
                return self.endTest()
            elif xlen < 20:
                self.log('ERROR: got unexpected XLEN: {}'.format(xlen))
                return self.endTest()
            else:
                self.recvBuf = b''
                self.expectedLen = 1

        elif self.state == self.State.RunD:
            self.log(
                f"  Program Readback:\n  {binascii.hexlify(self.recvBuf).decode('ascii')}")
            if received != USER_PROGRAM:
                self.log('ERROR: corrupted user program')
                return self.endTest()
            elif len(self.recvBuf) > len(USER_PROGRAM):
                self.log('WARNING: extra bytes received')
            self.recvBuf = b''
            self.log("Program memory content verified")

            self.state = self.State.RunG
            Serial << b'G'
            Serial << self.int2bytes(addr)
            self.expectedLen = 1

        elif self.state == self.State.RunG:
            if received == b'\x80':
                self.log('ERROR: exception occurred')
                return self.endTest()
            elif received != b'\x06':
                self.log('ERROR: start mark should be 0x06')
                return self.endTest()
            self.log(f"DEBUG: recvBuf: {self.recvBuf} during RunG")
            self.recvBuf = self.recvBuf[1:]
            self.time_start = timer()
            self.state = self.State.WaitG
            self.expectedLen = 1

        elif self.state == self.State.WaitG:
            self.log(f"DEBUG: recvBuf: {self.recvBuf} during WaitG")
            self.recvBuf = self.recvBuf[1:]
            if received == b'\x80':
                self.log('ERROR: exception occurred')
                return self.endTest()
            elif received == b'\x07':
                elapsed = timer() - self.time_start
                self.log(f'Elapsed time: {elapsed:.3f}s')

                self.state = self.State.RunR
                self.recvBuf = b''
                self.expectedLen = 31*4
                Serial << b'R'

        elif self.state == self.State.RunR:
            regList = [self.bytes2int(received[i:i+4])
                       for i in range(0, 31*4, 4)]
            self.log('\n'.join([f"  R{i+1} = {regList[i]:08x}"
                                for i in range(31)]))
            for pair in REG_VERIFICATION:
                if regList[pair[0]-1] != pair[1]:
                    self.log(f"ERROR: R{pair[0]} should equal {pair[1]:08x}")
                    return self.endTest()
            self.recvBuf = b''
            self.log("Register value verified")

            self.state = self.State.RunD2
            self.expectedLen = len(MEM_VERIFICATION)
            Serial << b'D'
            Serial << self.int2bytes(0x80400100)
            Serial << self.int2bytes(len(MEM_VERIFICATION))

        elif self.state == self.State.RunD2:
            self.log(
                f"  Data Readback:\n  {binascii.hexlify(self.recvBuf).decode('ascii')}")
            if received != MEM_VERIFICATION:
                self.log('ERROR: data memory content mismatch')
                return self.endTest()
            elif len(self.recvBuf) > len(MEM_VERIFICATION):
                self.log('WARNING: extra bytes received')
            self.recvBuf = b''
            self.log("Data memory content verified")

            self.state = self.State.Done
            return self.endTest()

    @Serial  # On receiving from serial port
    def recv(self, dataBytes):
        self.recvBuf += dataBytes
        while len(self.recvBuf) >= self.expectedLen:
            end = self.stateChange(self.recvBuf[:self.expectedLen])
            if end:
                break

    @Timer
    def timeout(self):
        self.log(f"ERROR: timeout during {self.state.name}")
        self.endTest()

    @started
    def initialize(self):
        self.state = self.State.WaitBoot
        self.expectedLen = len(self.bootMessage)
        DIP << 0
        +Reset
        BaseRAM[:] = base64.b64decode(RESOURCES['kernel_bin'])
        # Serial.open(1, baud=115200)
        Serial.open(0, baud=9600)
        -Reset
        Timer.oneshot(3000)  # timeout in 2 seconds


USER_PROGRAM = binascii.unhexlify(  # in Little-Endian
    # ###### User Program Assembly ######
    # 80100000 <_start>:
    '93621000'  # ori     t0,zero,1
    '13631000'  # ori     t1,zero,1
    '93644000'  # ori     s1,zero,4
    '370f4080'  # lui     t5,0x80400
    '130fcf7f'  # addi    t5,t5,2044 # 804007fc <__global_pointer$+0x2fef84>
    '37054080'  # lui     a0,0x80400
    '13050510'  # addi    a0,a0,256 # 80400100 <__global_pointer$+0x2fe888>
    'b3836200'  # add     t2,t0,t1
    '93620300'  # ori     t0,t1,0
    '13e30300'  # ori     t1,t2,0
    '23206500'  # sw      t1,0(a0)
    '33059500'  # add     a0,a0,s1
    '6304e501'  # beq     a0,t5,80100038 <check>
    'e30400fe'  # beqz    zero,8010001c <_start+0x1c>

    # 80100038 <check>:
    '93621000'  # ori     t0,zero,1
    '13631000'  # ori     t1,zero,1
    '37054080'  # lui     a0,0x80400
    '13050510'  # addi    a0,a0,256 # 80400100 <__global_pointer$+0x2fe888>
    'b3836200'  # add     t2,t0,t1
    '93620300'  # ori     t0,t1,0
    '13e30300'  # ori     t1,t2,0
    '032e0500'  # lw      t3,0(a0)
    '6304c301'  # beq     t1,t3,80100060 <check+0x28>
    '630c0000'  # beqz    zero,80100074 <end>
    '33059500'  # add     a0,a0,s1
    '6304e501'  # beq     a0,t5,8010006c <succ>
    'e30000fe'  # beqz    zero,80100048 <check+0x10>

    # 8010006c <succ>:
    '13635055'  # ori     t1,zero,1365
    '23206500'  # sw      t1,0(a0)

    # 80100074 <end>:
    '67800000'  # ret
)

REG_VERIFICATION = [(5, 0xb72df7bb), (6, 0x555), (7, 0xe76f109d),
                    (9, 0x00000004), (10, 0x804007fc), (28, 0xe76f109d),
                    (30, 0x804007fc)]

# correct answer in ram
MEM_VERIFICATION = binascii.unhexlify(
    '020000000300000005000000080000000d000000150000002200000037000000'
    '5900000090000000e90000007901000062020000db0300003d060000180a0000'
    '551000006d1a0000c22a00002f450000f16f000020b500001125010031da0100'
    '42ff020073d90400b5d8070028b20c00dd8a1400053d2100e2c73500e7045700'
    'c9cc8c00b0d1e300799e700129705402a20ec503cb7e19066d8dde09380cf80f'
    'a599d619dda5ce29823fa5435fe5736de12419b1400a8d1e212fa6cf613933ee'
    '8268d9bde3a10cac650ae66948acf215adb6d87ff562cb95a219a415977c6fab'
    '399613c1d012836c09a9962dd9bb199ae264b0c7bb20ca619d857a2958a6448b'
    'f52bbfb44dd2034042fec2f48fd0c634d1ce8929609f505e316eda87910d2be6'
    'c27b056e53893054150536c2688e66167d939cd8e52103ef62b59fc747d7a2b6'
    'a98c427ef063e53499f027b389540de82245359bab994283cdde771e7878baa1'
    '455732c0bdcfec6102271f22bff60b84c11d2ba68014372a413262d0c14699fa'
    '0279fbcac3bf94c5c538909088f824564d31b5e6d529da3c225b8f23f7846960'
    '19e0f883106562e429455b6839aabd4c62ef18b59b99d601fd88efb69822c6b8'
    '95abb56f2dce7b28c2793198ef47adc0b1c1de58a0098c1951cb6a72f1d4f68b'
    '42a061fe3375588a7515ba88a88a12131da0cc9bc52adfaee2caab4aa7f58af9'
    '89c0364430b6c13db976f881e92cbabfa2a3b2418bd06c012d741f43b8448c44'
    'e5b8ab879dfd37cc82b6e3531fb41b20a16aff73c01e1b9461891a0821a8359c'
    '823150a4a3d98540250bd6e4c8e45b25edef310ab5d48d2fa2c4bf3957994d69'
    'f95d0da350f75a0c495568af994cc3bbe2a12b6b7beeee265d901a92d87e09b9'
    '350f244b0d8e2d04429d514f4f2b7f5391c8d0a2e0f34ff671bc209951b0708f'
    'c26c9128131d02b8d58993e0e8a69598bd302979a5d7be116208e88a07e0a69c'
    '69e88e2770c835c4d9b0c4eb4979faaf222abf9b6ba3b94b8dcd78e7f8703233'
    '853eab1a7dafdd4d02ee88687f9d66b6818bef1e002956d581b445f481dd9bc9'
    '0292e1bd836f7d8785015f450871dccc8d723b1295e317df225653f1b7396bd0'
    'd98fbec190c929926959e853f92212e6627cfa395b9f0c20bd1b075a18bb137a'
    'd5d61ad4ed912e4ec2684922affa77707163c192205e390391c1fa95b11f3499'
    '42e12e2ff30063c835e291f728e3f4bf5dc586b785a87b77e26d022f67167ea6'
    '498480d5b09afe7bf91e7f51a9b97dcda2d8fc1e4b927aeced6a770b38fdf1f7'
    '256869035d655bfb82cdc4fedf3220fa6100e5f8403305f3a133eaebe166efde'
    '829ad9ca6301c9a9e59ba274489d6b1e2d390e9375d679b1a20f884417e601f6'
    'b9f5893ad0db8b3089d1156b59ada19be27eb7063b2c59a21dab10a958d7694b'
    '75827af4cd59e43f42dc5e340f3643745112a2a86048e51cb15a87c511a36ce2'
    'c2fdf3a7d3a0608a959e5432683fb5bcfddd09ef651dbfab62fbc89ac7188846'
    '291451e1f02cd92719412a09096e033122af2d3a2b1d316b4dcc5ea578e98f10'
    'c5b5eeb53d9f7ec602556d7c3ff4eb42414959bf803d4502c1869ec141c4e3c3'
    '024b8285430f6649455ae8ce88694e18cdc336e7552d85ff22f1bbe6771e41e6'
    '990ffdcc102e3eb3a93d3b80b96b793362a9b4b31b152ee77dbee29a98d31082'
    '1592f31cad65049fc2f7f7bb6f5dfc5a3155f416a0b2f071d107e58871bad5fa'
    '42c2ba83b37c907ef53e4b02a8bbdb809dfa268345b60204e2b0298727672c8b'
    '09185612307f829d3997d8af69165b4da2ad33fd0bc48e4aad71c247b8355192'
    '65a713da1ddd646c828478469f61ddb221e655f9c04733ace12d89a5a175bc51'
    '82a345f723190249a5bc4740c8d549896d9291c93568db52a2fa6c1cd762486f'
    '795db58b50c0fdfac91db38619deb081e2fb6308fbd9148addd57892d8af8d1c'
    'b58506af8d3594cb42bb9a7acff02e4611acc9c0e09cf806f148c2c7d1e5bace'
    'c22e7d96931438655543b5fbe857ed603d9ba25c25f38fbd628e321a8781c2d7'
    'e90ff5f17091b7c959a1acbbc932648522d41041eb0675c60ddb8507f8e1facd'
    '05bd80d5fd9e7ba3025cfc78fffa771c015774950052ecb101a9604701fb4cf9'
    '02a4ad40039ffa390543a87a08e2a2b40d254b2f1507eee3222c3913373327f7'
    '595f600a90928701e9f1e70b79846f0d62765719dbfac6263d711e40186ce566'
    '55dd03a76d49e90dc226edb42f70d6c2f196c37720079a3a119e5db231a5f7ec'
    '4243559f73e84c8cb52ba22b2814efb7dd3f91e30554809be293117fe7e7911a'
    'c97ba399b06335b479dfd84d29430e02a222e74fcb65f5516d88dca138eed1f3'
    'a576ae95dd64808982db2e1f5f40afa8e11bdec7405c8d7021786b3861d4f8a8'
    '824c64e1e3205d8a656dc16b488e1ef6adfbdf61f589fe57a285deb9970fdd11'
    '3995bbcbd0a498dd093a54a9d9deec86e2184130bbf72db79d106fe755050000'
)
