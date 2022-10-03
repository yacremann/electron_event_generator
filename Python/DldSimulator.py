"""
Library to simplify communicating with the Electron generator board

Date: 06.2022
Author: Jingo Bozzini
"""


import serial

class DldSimulatorException(RuntimeError):
    def __init__(self, arg):
        self.args = (arg, arg)

"""
PulseConfig is used to structure for the data 
t0, x, y, active(if enabled). 
    t0     -> delay in cycles (80MHz)
    x      -> electron in x-axis
    y      -> electron in y-axis
    active -> if the electron is actually going out
    
Readability of the code will improve.
"""
class PulseConfig:
    t0     =  100
    x      =    0
    y      =    0
    active = True
    
    """
    Checking if t0, x, y is in the range.
    Output is true if valid.
        x -> -32 ... 31
        y -> -32 ... 31
        t0 -> 0 ... 800
    """ 
    def validate(self):
        valid = True
        if (self.t0 < 0):
            valid = False
        if (self.t0 > 800):
            valid = False
        if (self.x < -32):
            valid = False
        if (self.x > 31):
            valid = False
        if (self.y < -32):
            valid = False
        if (self.y > 31):
            valid = False
        return valid
            
    """
    It generates from t0, x, y, active a 32bit value which is
    used to communicate with the processor.
    Structure of 32bit:
        bit0 - bit9   = t0
        bit10 - bit15 = x
        bit16 - bit21 = y
        bit22         = active
        
        bit23 - bit31 = unused
    """
    def createControlWord(self):
        if (not self.validate()):
            raise DldSimulatorException("Invalid pulse configuration")
        controlWord = self.t0
        controlWord = controlWord | (((self.x + 32) & 0b111111) << 10)
        controlWord = controlWord | (((self.y + 32) & 0b111111) << 16)
        if (self.active):
            controlWord = controlWord | (0x1 << 22)
        return controlWord
    
    """
    It generates from a 32bit value t0, x, y, active.
    This can be used to save the data in the correct structure.
    Structure of 32bit:
        bit0 - bit9   = t0
        bit10 - bit15 = x
        bit16 - bit21 = y
        bit22         = active
        
        bit23 - bit31 = unused
    """
    def readControlWord(self, controlWord):
        self.t0 = controlWord & 0b1111111111
        self.x  = ((controlWord >> 10) & 0b111111) -32
        self.y  = ((controlWord >> 16) & 0b111111) -32
        self.active = (((controlWord >> 22) & 0x01) == 1)
        if (not self.validate()):
            raise DldSimulatorException("Invalid pulse configuration")
    """
    NICHT SICHER!!!
    Gives out the 4 values in a non cryptic form
    (recommended for print)
    """
    def to_string(self):
        return "t0 = " + str(self.t0) + "  x = " + str(self.x) + "  y = " + str(self.y) + " active = " + str(self.active)
    
    """
    Use to save value.
    Can also be done manually
    """
    def set(self, t0, x, y, active):
        self.x = x
        self.y = y
        self.t0 = t0
        self.active = active
        




"""
DldSimulator is responsible for the communication between PC and Electron generator board.
It is a UART interface which has the settings:
    - 115200 baudrate
    - no parity bit 
    - 1 stop bit.
    
Structre of read/write string:
    - read/write (r/w)
    - address
    - data (only write)
    
Each components are separated with a space.
The address and data are in 32bit, hex format

Currently only the address 0x44a0ffff - 0x44a0_ffff are write/readable.
If trying to do something outside the range it displays "invalid address".
The range might change in the future but currently it is set like this.

"""    
class DldSimulator:
    
    ADDR_START_CONFIG       = 0x44a0_0004
    ADDR_MULTI_SPECTRUM_GEN = 0x44a0_0100
    ADDR_LIST_GEN1_BASE     = 0x44a0_0200
    ADDR_LIST_GEN2_BASE     = 0x44a0_0400
    
    """
    execute on start
    """
    def __init__(self, commPort):
        self.s = serial.Serial(commPort, baudrate=115200)
        self.s.timeout = 1.0
        self.s.reset_input_buffer()
        self.s.reset_output_buffer()
        
        
    def __delete__(self):
        self.s.close()
        

    """
    Write one word (32 bits) to the data bus
    
    Structre of write string:
        - write (w)
        - address
        - data
        
    Each components are separated with a space.
    The address and data are in 32bit, hex format.
    
    If the sending of data was successful, the Board sends "OK\n" back.
    If it didn't work, a message Communication error is seen.
    """
    def writeToBus(self, addr, data):
        send_str = "w " + hex(addr) + " " + hex(data) + "\n"
        self.s.write(send_str.encode('ascii'))
        ret = self.s.readline()
        if (ret.decode('ascii') != 'OK\n'):
            raise DldSimulatorException("Communication error")

    """
    Read one word (32 bits) from the data bus
    
    Structre of read string:
        - read (r)
        - address
        
    Each components are separated with a space.
    The address are in 32bit, hex format.
    
    If the sending of data was successful, the Board sends the data in address back.
    If it didn't work, rubbish wil come out.
    """
    def readFromBus(self, addr):
        send_str = "r " + hex(addr) + "\n"
        self.s.write(send_str.encode('ascii'))
        ret = self.s.readline().decode('ascii')
        return int(ret, 16)

    """
    Use the external start signal. The start interval settings are unaltered.
    1 = used
    0 = unused
    """
    def useExternalStart(self, extStart):
        oldValue = self.readFromBus(self.ADDR_START_CONFIG)
        if (extStart):
            self.writeToBus(self.ADDR_START_CONFIG, oldValue | 0x0001_0000)
        else:
            self.writeToBus(self.ADDR_START_CONFIG, oldValue & ~0x0001_0000)
    
    """
    Return True if the external start signal is used.
    1 = used
    0 = unused
    """
    def isExternalStart(self):
        value = self.readFromBus(self.ADDR_START_CONFIG)
        return ((value & 0x0001_0000) == 0x0001_0000)

    """
    Set the start interval (num. of clock cycles between internally generated start pulses)
    This method does not switch to the internally generated start signal.
    Range for the Intervall is between 100 - 0xffff which means a frequency between 1MHz - 1.5kHz(?).
    """
    def setInternalStartInterval(self,interval):
        if (interval < 100):
            raise DldSimulatorException("Start inverval too small")
        if (interval > 0xffff):
            raise DldSimulatorException("Start inverval too large")
        oldValue = self.readFromBus(self.ADDR_START_CONFIG)
        self.writeToBus(self.ADDR_START_CONFIG, (oldValue & 0xffff_0000) | interval)
    
    
    """
    Get the start interval (num. of clock cycles between internally generated start pulses)
    """
    def getInternalStartInterval(self):
        value = self.readFromBus(self.ADDR_START_CONFIG)
        return (value & 0xffff)

    """
    Activate numOfGenerators spectrum generators
        numOfGenerators: int, number of generators (0 ... 32)
    """
    def setActiveSpectrumGenerators(self, numOfGenerators):
        if (numOfGenerators < 0):
            raise DldSimulatorException("Num of generators can not be negative")
        if (numOfGenerators > 32):
            raise DldSimulatorException("Num of generators can not be larger than 32")
        value = 0xffffffff >> (32-numOfGenerators)
        self.writeToBus(self.ADDR_MULTI_SPECTRUM_GEN, value)
        
    """
    Get the number of active spectrum generators
    """    
    def getActiveSpectrumGenerators(self):
        value = self.readFromBus(self.ADDR_MULTI_SPECTRUM_GEN)
        return bin(value).count("1")
    
    """
    Sets the values in ListGenerator through a list (PulseConfig format).
    Max number of values are 64. 
    Due to the fact that there are 2 ListGenerator, choose which one you want to override.
    """
    def setListGenerator(self, channel, listOfPulses):
        if (channel < 1):
            raise DldSimulatorException("Channel number can not be negative")
        if (channel > 2):
            raise DldSimulatorException("Channel number can not be larger than 1")
        
        numOfPulses = len(listOfPulses)
        
        if (numOfPulses > 64):
            raise DldSimulatorException("List of pulses to large, max. 64")
        
        if (channel == 1):        
            baseAddr = self.ADDR_LIST_GEN1_BASE
        else:
            baseAddr = self.ADDR_LIST_GEN2_BASE
        
        for p in listOfPulses:
            if (not p.validate()):
                raise DldSimulatorException("Invalid pulse configuration")
        
        addrCounter = baseAddr
        for p in listOfPulses:
            self.writeToBus(addrCounter, p.createControlWord())
            addrCounter = addrCounter + 4
            
        if (numOfPulses < 64):
            self.writeToBus(addrCounter, 0x00)
        
    """
    Gives out the values saved in Listgenerator (PulseConfig format)
    """
    def getListGenerator(self, channel):
        if (channel < 1):
            raise DldSimulatorException("Channel number can not be negative")
        if (channel > 2):
            raise DldSimulatorException("Channel number can not be larger than 1")
            
        if (channel == 1):        
            baseAddr = self.ADDR_LIST_GEN1_BASE
        else:
            baseAddr = self.ADDR_LIST_GEN2_BASE
        
        result = []
        currentElementIndex = 0
        while(True):
            if (currentElementIndex >= 64):
                break
            word = self.readFromBus(baseAddr+currentElementIndex*4)
            if (word == 0):
                break
            p = PulseConfig()
            p.readControlWord(word)
            result.append(p)
            currentElementIndex = currentElementIndex + 1
        return result
    
    """
    Enable ListGenerator 
    1 = used
    0 = unused
    """
    def setListGeneratorActive(self, channel, active):
        if (channel < 1):
            raise DldSimulatorException("Channel number can not be negative")
        if (channel > 2):
            raise DldSimulatorException("Channel number can not be larger than 1")
            
        if (channel == 1):        
            baseAddr = self.ADDR_LIST_GEN1_BASE
        else:
            baseAddr = self.ADDR_LIST_GEN2_BASE
        
        self.writeToBus(baseAddr + 0x100, active)
        
        
    """
    Read whether or not the ListGenerator is active
    1 = used
    0 = unused
    """    
    def isListGeneratorActive(self, channel):
        if (channel < 1):
            raise DldSimulatorException("Channel number can not be negative")
        if (channel > 2):
            raise DldSimulatorException("Channel number can not be larger than 1")
            
        if (channel == 1):        
            baseAddr = self.ADDR_LIST_GEN1_BASE
        else:
            baseAddr = self.ADDR_LIST_GEN2_BASE
            
        return (self.readFromBus(baseAddr + 0x100) == 0x01)
        
