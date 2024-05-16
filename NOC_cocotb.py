import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.binary import BinaryValue
from cocotb.types import LogicArray, concat

# bodyZeros = BinaryValue(0, n_bits=16)
# bodyOnes = BinaryValue(1, n_bits=16)

class NOCTester:
    def __init__(self, RADIX_IN, RADIX_OUT, ADDR_WIDTH, DATA_WIDTH):
        self.RADIX_IN = RADIX_IN
        self.RADIX_OUT = RADIX_OUT
        self.ADDR_WIDTH = ADDR_WIDTH
        self.DATA_WIDTH = DATA_WIDTH
        self.packets = [[] for _ in range(RADIX_OUT)]

    def send(self, src=None, dest=None, payload=None):
        if src is None:
            src = random.randint(0, self.RADIX_IN)
        if dest is None:
            dest = random.randint(0, self.RADIX_OUT)
        if payload is None:
            payload = random.randint(0, 2**self.DATA_WIDTH)
        packet = BinaryValue(dest, n_bits=self.ADDR_WIDTH, bigEndian=False).binstr + BinaryValue(payload, n_bits=self.DATA_WIDTH, bigEndian=False).binstr
        # print(packet)
        vector = ""
        for i in range(self.RADIX_IN):
            if (i != src):
                vector += f'{0:0>20b}'
            else:
                vector += packet
        return vector

    def receive(self, src, dest):
        pass




# def generate_flit_str(dest=None, payload=None):
#     if dest is None:
#         dest = random.randint(0, 4)
#     if payload is None:
#         payload = random.randint(0, 65536)
#     return BinaryValue(payload, n_bits=16, ).binstr + BinaryValue(dest, n_bits=4).binstr

@cocotb.test()
async def one_flit(dut):
    Tester = NOCTester(4, 4, 4, 16)
    # print("generated vector:")
    # print(f'{0:0>20b}')
    # print(Tester.send(0, 15, 9))
    clk = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clk.start(start_high=False))
    dut.rst_l.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_l.value = 1
    dut.FIFO_ENQ.value = BinaryValue(1, n_bits=4, bigEndian=False)
    dut.FIFO_IN.value = LogicArray(Tester.send(0, 15, 9))
    dut.FIFO_FULL_downstream.value = LogicArray('1111')
    print("monitor:")
    print(dut.FIFO_ENQ.value)
    print(dut.FIFO_ENQ_downstream.value)
    await RisingEdge(dut.clk)
    # dut.FIFO_ENQ.value = LogicArray('1111')
    dut.FIFO_FULL_downstream.value = BinaryValue(0, n_bits=4, bigEndian=False)
    print("monitor:")
    print(dut.FIFO_ENQ.value)
    print(dut.FIFO_ENQ_downstream.value)
    await RisingEdge(dut.clk)
    dut.FIFO_ENQ.value = BinaryValue(0, n_bits=4, bigEndian=False)
    for _ in range(10):
        print("monitor:")
        print(dut.FIFO_ENQ.value)
        print(dut.FIFO_ENQ_downstream.value)
        await RisingEdge(dut.clk)
    assert (dut.FIFO_ENQ_downstream.value == BinaryValue(0, n_bits=4, bigEndian=False))