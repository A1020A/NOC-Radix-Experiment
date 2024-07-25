import cocotb
import random
import math
import sys
import logging
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, ReadWrite
from cocotb.binary import BinaryValue
from cocotb.types import LogicArray, concat

def get_len_2d(arr:list):
    return sum([len(i) for i in arr])

def binstr_bitwise_or(a, b):
    a_str = a.binstr
    b_str = b.binstr
    assert (len(a_str) == len(b_str)) 
    return BinaryValue("".join(["1" if a_str[i] == "1" or b_str[i] == "1" else "0" for i in range(len(a_str))]), n_bits=len(a_str), bigEndian=False)

class NOCTester:
    def __init__(self, RADIX_IN, RADIX_OUT, ADDR_WIDTH, DATA_WIDTH, logging_task):
        self.RADIX_IN = RADIX_IN
        self.RADIX_OUT = RADIX_OUT
        self.ADDR_WIDTH = ADDR_WIDTH
        self.DATA_WIDTH = DATA_WIDTH
        # self.NETWORK_DEPTH = NETWORK_DEPTH
        self.logging_task = logging_task
        self.packet_len = self.ADDR_WIDTH + self.DATA_WIDTH
        self.packets = [[] for _ in range(RADIX_OUT)] # keeps track of packets at each output node

    def send(self, FIFO_FULL, src=None, dest=None, payload=None):
        while (1):
            if src is None:
                src = random.randrange(0, self.RADIX_IN)
            else:
                if (FIFO_FULL[self.RADIX_IN-1-src] == "1"):
                    self.logging_task.log.debug(f"intended source src:{src} is full right now")
                    raise ValueError("FIFO_FULL is full")
                # print(f"FIFO_FULL:{FIFO_FULL}")
            if dest is None:
                dest = random.randrange(0, self.RADIX_OUT)
            if payload is None:
                payload = random.randrange(0, 2**self.DATA_WIDTH)
            if (FIFO_FULL[self.RADIX_IN-1-src] == "0"):
                break

        addr_eff=round(math.log2(self.RADIX_OUT))
        packet = BinaryValue(dest, n_bits=addr_eff, bigEndian=False).binstr + ("0"*(self.ADDR_WIDTH - addr_eff)) + BinaryValue(payload, n_bits=self.DATA_WIDTH, bigEndian=False).binstr
        # print(packet)
        self.packets[dest].append(packet)
        data_vec = ""
        for i in range(self.RADIX_IN):
            if (i != src):
                data_vec = ("0"*self.packet_len) + data_vec
            else:
                data_vec = packet + data_vec
        enq_vec =  BinaryValue(1 << src, n_bits=self.RADIX_IN, bigEndian=False)
        self.logging_task.log.debug(f"sending from src:{src} to dest:{dest}")
        self.logging_task.log.debug(f"sending pkt: {f'0x{int(packet, 2):12x}':^12}")
        return enq_vec, LogicArray(data_vec)
    

    def receive(self, FIFO_ENQ_downstream, data_vec):
        if (FIFO_ENQ_downstream != BinaryValue(0, n_bits=self.RADIX_OUT, bigEndian=False)):
            for idx, i in enumerate(FIFO_ENQ_downstream.value.binstr):
                # print(f"idx:{idx} i:{i}")
                if (i == "1"):
                    received_pkt = data_vec.value.binstr[idx*self.packet_len:idx*self.packet_len+self.packet_len]
                    self.logging_task.log.debug(f"receiving packet from dest:{self.RADIX_OUT-1-idx}, expecting {f'0x{int(received_pkt, 2):12x}':^12}")
                    self.debug_print_wait_buffer(self.RADIX_OUT-1-idx)
                    assert(data_vec.value.binstr[idx*self.packet_len:idx*self.packet_len+self.packet_len] in self.packets[self.RADIX_OUT-1-idx])
                    self.packets[self.RADIX_OUT-1-idx].remove(data_vec.value.binstr[idx*self.packet_len:idx*self.packet_len+self.packet_len])
                    self.logging_task.log.debug("success")
        pass

    def end(self):
        for i in range(self.RADIX_OUT):
            assert (len(self.packets[i]) == 0)

    def debug_print_wait_buffer(self, node: int):
        if (len(self.packets[node]) > 0):
            for i in self.packets[node]:
                self.logging_task.log.debug(f"pkt: {f'0x{int(i, 2):12x}':^12}")
        else:
            self.logging_task.log.debug(f"Buffer Empty for output node {node}")
        


# @cocotb.test()
# async def one_flit(dut):
#     args = cocotb.plusargs
#     Tester = NOCTester(int(args['RADIX_IN']), int(args['RADIX_OUT']), int(args['ADDR_WIDTH']), int(args['DATA_WIDTH']))
#     clk = Clock(dut.clk, 10, units="us")
#     cocotb.start_soon(clk.start(start_high=False))
#     dut.rst_l.value = 0
#     for _ in range(3):
#         await RisingEdge(dut.clk)
#     dut.rst_l.value = 1
#     enq_vec, data_vec = Tester.send(dut.FIFO_FULL.value.binstr, dest=1)
#     dut.FIFO_ENQ.value = enq_vec
#     dut.FIFO_IN.value = LogicArray(data_vec)
#     dut.FIFO_FULL_downstream.value = LogicArray("1"*Tester.RADIX_OUT)
#     await RisingEdge(dut.clk)
#     enq_vec, data_vec = Tester.send(dut.FIFO_FULL.value.binstr, dest=1)
#     dut.FIFO_ENQ.value = enq_vec
#     dut.FIFO_IN.value = LogicArray(data_vec)
#     # await RisingEdge(dut.clk)
#     for _ in range(10):
#         await RisingEdge(dut.clk)
#         dut.FIFO_FULL_downstream.value = BinaryValue(0, n_bits=Tester.RADIX_OUT, bigEndian=False)
#         dut.FIFO_ENQ.value = BinaryValue(0, n_bits=Tester.RADIX_IN, bigEndian=False)
#         # dut.FIFO_IN.value = LogicArray("1"*80)
#         Tester.receive(dut.FIFO_ENQ_downstream, dut.FIFO_OUT)
#     assert (dut.FIFO_ENQ_downstream.value == BinaryValue(0, n_bits=Tester.RADIX_OUT, bigEndian=False))
#     Tester.end()



@cocotb.test()
async def fully_random(dut):
    # seed = random.randrange(sys.maxsize)
    # rng = random.Random(seed)
    # print(f"seed:{seed}")
    # random.seed(5592969042884215283)

    # initialize the tester, DUT, and logging
    args = cocotb.plusargs
    clk = Clock(dut.clk, 10, units="us")
    task_clk = cocotb.start_soon(clk.start(start_high=False))
    if (int(args['VERBOSE']) == 1):
        task_clk.log.setLevel(logging.DEBUG)
    else:
        task_clk.log.setLevel(logging.INFO)
    

    Tester = NOCTester(int(args['RADIX_IN']), int(args['RADIX_OUT']), int(args['ADDR_WIDTH']), int(args['DATA_WIDTH']), task_clk)
    task_clk.log.debug("Logging Started")
    dut.FIFO_FULL_downstream.value = BinaryValue("1"*Tester.RADIX_OUT, n_bits=Tester.RADIX_OUT, bigEndian=False)
    dut.rst_l.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_l.value = 1

    for _ in range(100):
        await RisingEdge(dut.clk)
        # await ReadOnly()
        task_clk.log.debug(f"----------new Cycle----------")
        task_clk.log.debug("Logging Cycle")
        enq_vec_final = BinaryValue(0, n_bits=Tester.RADIX_IN, bigEndian=False)
        data_vec_final = BinaryValue(0, n_bits=Tester.RADIX_IN*Tester.packet_len)
        num_to_send = random.randrange(0, Tester.RADIX_IN+1)
        task_clk.log.debug(f"trying to send {num_to_send} packets")
        task_clk.log.debug(f"FIFO_FULL:{dut.FIFO_FULL.value.binstr}")
        for i in random.sample(range(0, Tester.RADIX_IN), num_to_send):
            # print(f"trying to send packet from src {i}")
            try: 
                enq_vec, data_vec = Tester.send(dut.FIFO_FULL.value.binstr, src=i)
                enq_vec_final = binstr_bitwise_or(enq_vec, enq_vec_final)
                data_vec_final = binstr_bitwise_or(data_vec, data_vec_final)
            except ValueError:
                continue
        dut.FIFO_ENQ.value = enq_vec_final
        dut.FIFO_IN.value = data_vec_final
        task_clk.log.debug(f"enq_vec:{enq_vec_final.binstr}")
        if (dut.FIFO_FULL_downstream.value == BinaryValue(0, n_bits=Tester.RADIX_OUT, bigEndian=False)):
            Tester.receive(dut.FIFO_ENQ_downstream, dut.FIFO_OUT)

        if (random.randint(0, 10) < 8):
            dut.FIFO_FULL_downstream.value = BinaryValue(0, n_bits=Tester.RADIX_OUT, bigEndian=False)
        else:
            dut.FIFO_FULL_downstream.value = BinaryValue("1"*Tester.RADIX_OUT, n_bits=Tester.RADIX_OUT, bigEndian=False)
        
        task_clk.log.debug(f"FIFO_FULL_2:{dut.FIFO_FULL.value.binstr}")
    task_clk.log.debug("************write complete************")
    for _ in range(10):
        await RisingEdge(dut.clk)
        task_clk.log.debug(f"----------new Cycle----------")
        Tester.receive(dut.FIFO_ENQ_downstream, dut.FIFO_OUT)
        enq_vec_final = BinaryValue(0, n_bits=Tester.RADIX_IN, bigEndian=False)
        data_vec_final = BinaryValue(0, n_bits=Tester.RADIX_IN*Tester.packet_len)
        dut.FIFO_FULL_downstream.value = BinaryValue("1"*Tester.RADIX_OUT, n_bits=Tester.RADIX_OUT, bigEndian=False)
        dut.FIFO_ENQ.value = enq_vec_final
        dut.FIFO_IN.value = data_vec_final
    
    # print(get_len_2d(Tester.packets))
    # await RisingEdge(dut.clk)
    # dut.FIFO_FULL_downstream.value = BinaryValue(0, n_bits=Tester.RADIX_OUT, bigEndian=False)
    # Tester.receive(dut.FIFO_ENQ_downstream, dut.FIFO_OUT)
    # await RisingEdge(dut.clk)
    task_clk.log.debug("************begin clean-up************")
    # while (get_len_2d(Tester.packets) > 0):
    for _ in range(20):
        await RisingEdge(dut.clk)
        task_clk.log.debug(get_len_2d(Tester.packets))
        task_clk.log.debug(f"----------new Cycle----------")
        dut.FIFO_FULL_downstream.value = BinaryValue(0, n_bits=Tester.RADIX_OUT, bigEndian=False)
        Tester.receive(dut.FIFO_ENQ_downstream, dut.FIFO_OUT)
    
    for node in Tester.packets:
        if (len(node) > 0):
            for i in node:
                task_clk.log.debug(f"pkt: {f'0x{int(i, 2):12x}':^12}")

    Tester.end()
