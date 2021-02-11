#################################################################################
# BSD 3-Clause License
# 
# Copyright (c) 2020, Jose R. Garcia
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#################################################################################
# File name     : memory_intfc_read_slave_config.py
# Author        : Jose R Garcia
# Created       : 2020/11/05 20:11:12
# Last modified : 2020/12/02 21:58:51
# Project Name  : UVM Python Verification Library
# Module Name   : memory_intfc_read_slave_config
# Description   : Memory Interface Configuraion object.
#
# Additional Comments:
#
#################################################################################
from uvm import *
from uvm_externals.Wishbone_Pipeline_Master.wb_master_seq import *

class reg_model(UVMReg):


    def __init__(self, name="reg_model", n_bits=32):
        super().__init__(name, n_bits)
        self.reg_field = None


    def build(self):
        self.reg_field = UVMRegField.type_id.create("reg_field", self)
        # def configure(self, parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand,
        #        individually_accessible):
        self.reg_field.configure(self, 32, 0, "RW", True, 0, 1, 0, True)
        # for back-door access


    #self.configure(hdl_path="reg_field")


uvm_object_utils(reg_model)


class reg_block(UVMRegBlock):


    def __init__(self, name="reg_block", n_bits=32):
        super().__init__(name, n_bits)
        self.reg_map = None
        self.register = None


    def build(self):
        self.register0  = reg_model.type_id.create("register0", self)
        self.register1  = reg_model.type_id.create("register1", self)
        self.register2  = reg_model.type_id.create("register2", self)
        self.register3  = reg_model.type_id.create("register3", self)
        self.register4  = reg_model.type_id.create("register4", self)
        self.register5  = reg_model.type_id.create("register5", self)
        self.register6  = reg_model.type_id.create("register6", self)
        self.register7  = reg_model.type_id.create("register7", self)
        self.register8  = reg_model.type_id.create("register8", self)
        self.register9  = reg_model.type_id.create("register9", self)
        self.register10 = reg_model.type_id.create("register10", self)
        self.register11 = reg_model.type_id.create("register11", self)
        self.register12 = reg_model.type_id.create("register12", self)
        self.register13 = reg_model.type_id.create("register13", self)
        self.register14 = reg_model.type_id.create("register14", self)
        self.register15 = reg_model.type_id.create("register15", self)
        self.register16 = reg_model.type_id.create("register16", self)
        self.register17 = reg_model.type_id.create("register17", self)
        self.register18 = reg_model.type_id.create("register18", self)
        self.register19 = reg_model.type_id.create("register19", self)
        self.register20 = reg_model.type_id.create("register20", self)
        self.register21 = reg_model.type_id.create("register21", self)
        self.register22 = reg_model.type_id.create("register22", self)
        self.register23 = reg_model.type_id.create("register23", self)
        self.register24 = reg_model.type_id.create("register24", self)
        self.register25 = reg_model.type_id.create("register25", self)
        self.register26 = reg_model.type_id.create("register26", self)
        self.register27 = reg_model.type_id.create("register27", self)
        self.register28 = reg_model.type_id.create("register28", self)
        self.register29 = reg_model.type_id.create("register29", self)
        self.register30 = reg_model.type_id.create("register30", self)
        self.register31 = reg_model.type_id.create("register31", self)

        self.register0.configure(blk_parent=self)
        self.register1.configure(blk_parent=self)
        self.register2.configure(blk_parent=self)
        self.register3.configure(blk_parent=self)
        self.register4.configure(blk_parent=self)
        self.register5.configure(blk_parent=self)
        self.register6.configure(blk_parent=self)
        self.register7.configure(blk_parent=self)
        self.register8.configure(blk_parent=self)
        self.register9.configure(blk_parent=self)
        self.register10.configure(blk_parent=self)
        self.register11.configure(blk_parent=self)
        self.register12.configure(blk_parent=self)
        self.register13.configure(blk_parent=self)
        self.register14.configure(blk_parent=self)
        self.register15.configure(blk_parent=self)
        self.register16.configure(blk_parent=self)
        self.register17.configure(blk_parent=self)
        self.register18.configure(blk_parent=self)
        self.register19.configure(blk_parent=self)
        self.register20.configure(blk_parent=self)
        self.register21.configure(blk_parent=self)
        self.register22.configure(blk_parent=self)
        self.register23.configure(blk_parent=self)
        self.register24.configure(blk_parent=self)
        self.register25.configure(blk_parent=self)
        self.register26.configure(blk_parent=self)
        self.register27.configure(blk_parent=self)
        self.register28.configure(blk_parent=self)
        self.register29.configure(blk_parent=self)
        self.register30.configure(blk_parent=self)
        self.register31.configure(blk_parent=self)

        self.register0.build()
        self.register1.build()
        self.register2.build()
        self.register3.build()
        self.register4.build()
        self.register5.build()
        self.register6.build()
        self.register7.build()
        self.register8.build()
        self.register9.build()
        self.register10.build()
        self.register11.build()
        self.register12.build()
        self.register13.build()
        self.register14.build()
        self.register15.build()
        self.register16.build()
        self.register17.build()
        self.register18.build()
        self.register19.build()
        self.register20.build()
        self.register21.build()
        self.register22.build()
        self.register23.build()
        self.register24.build()
        self.register25.build()
        self.register26.build()
        self.register27.build()
        self.register28.build()
        self.register29.build()
        self.register30.build()
        self.register31.build()

        self.reg_map = UVMRegBlock.create_map(self, "reg_map",0, 4, 0, True)
        #self.reg_map.configure(base_addr=0, n_bytes=4, endian=UVM_LITTLE_ENDIAN)

        self.reg_map.add_reg(rg=self.register0, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register1, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register2, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register3, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register4, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register5, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register6, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register7, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register8, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register9, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register10, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register11, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register12, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register13, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register14, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register15, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register16, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register17, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register18, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register19, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register20, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register21, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register22, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register23, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register24, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register25, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register26, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register27, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register28, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register29, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register30, offset=0, rights="RW")
        self.reg_map.add_reg(rg=self.register31, offset=0, rights="RW")
        # def add_reg(self, rg, offset, rights="RW", unmapped=0, frontdoor=None):


    #def configure(hdl_path="top.dut")
    #self.configure(self, None, "top.dut")
    
    
uvm_object_utils(reg_block)


class reg_adapter(UVMRegAdapter):


    def __init__(self, name="reg_adapter"):
        super().__init__(name)

    def reg2bus(self, rw):
        memory_intfc = wb_master_seq.type_id.create("memory_intfc")
        # memory_intfc.addr = rw.addr
        # memory_intfc.data = rw.data
        # memory_intfc.byte_enable = rw.byte_enable
        return memory_intfc


    def bus2reg(self, bus_item, rw):  # rw must be ref
        memory_intfc = None
        arr = []
        if (not sv.cast(arr,bus_item, wb_master_seq)):
            uvm_fatal("NOT_memory_intfc_read_slave_TYPE", "Provided bus_item is not of the correct type")
            return

        memory_intfc = arr[0]
        # rw.addr = memory_intfc.addr
        # rw.data = memory_intfc.data
        # rw.byte_enable = memory_intfc.byte_enable
        # rw.status = UVM_IS_OK
        return rw


uvm_object_utils(reg_adapter)
