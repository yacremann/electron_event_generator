import unittest
import glob
from DldSimulator import *

class TestDldSim(unittest.TestCase):

    def test_pulse_config(self):
        p = PulseConfig()
        # test set()
        p.set(123,12,-23,True)
        self.assertEqual(p.t0, 123)
        self.assertEqual(p.x ,  12)
        self.assertEqual(p.y , -23)
        self.assertEqual(p.active, True)
        # test validate()
        self.assertEqual(p.validate(), True)
        p.t0 = -1
        self.assertEqual(p.validate(), False)
        p.t0 = 123
        self.assertEqual(p.validate(), True)
        p.x = -33
        self.assertEqual(p.validate(), False)
        p.x = 12
        self.assertEqual(p.validate(), True)
        p.y = 32
        self.assertEqual(p.validate(), False)
        p.y = -23
        self.assertEqual(p.validate(), True)
        
        controlWord = p.createControlWord()
        self.assertEqual(controlWord, 0x49b07b)
        p.set(55,33,-99,True)
        with self.assertRaises(DldSimulatorException):
            p.createControlWord()
            
        p.readControlWord(0x49b07b)
        self.assertEqual(p.t0, 123)
        self.assertEqual(p.x ,  12)
        self.assertEqual(p.y , -23)
        self.assertEqual(p.active, True)
        
    def test_DldSimulator(self):
        tty = glob.glob("/dev/ttyUSB*")[1]  #depending on connected USB you might 
                                            #need to change which of the USB you take
        dld = DldSimulator(tty)
        dld.writeToBus(dld.ADDR_START_CONFIG, 0xdeadbeef)
        self.assertEqual(dld.readFromBus(dld.ADDR_START_CONFIG), 0xdeadbeef)
        
        # test start config
        dld.useExternalStart(True)
        self.assertEqual(dld.isExternalStart(), True)
        
        dld.useExternalStart(False)
        self.assertEqual(dld.isExternalStart(), False)
        with self.assertRaises(DldSimulatorException):
            dld.setInternalStartInterval(-1)
        with self.assertRaises(DldSimulatorException):
            dld.setInternalStartInterval(0x10000)
            
        dld.setInternalStartInterval(3456)
        self.assertEqual(dld.getInternalStartInterval(), 3456)
        self.assertEqual(dld.isExternalStart(), False)
        
        # test SpectrumGenerators
        with self.assertRaises(DldSimulatorException):
            dld.setActiveSpectrumGenerators(-1)
        with self.assertRaises(DldSimulatorException):
            dld.setActiveSpectrumGenerators(33)
        dld.setActiveSpectrumGenerators(11)
        self.assertEqual(dld.getActiveSpectrumGenerators(), 11)
        self.assertEqual(dld.readFromBus(dld.ADDR_MULTI_SPECTRUM_GEN), 0b11111111111)
        
        # test ListGenerator
        dld.setListGenerator(1, [])
        self.assertEqual(len(dld.getListGenerator(1)), 0)
        
        p0 = PulseConfig()
        p0.set(123,12,21,True)
        p1 = PulseConfig()
        p1.set(123,12,21,True)
        pf = PulseConfig()
        pf.set(123,456,789,True)
        with self.assertRaises(DldSimulatorException):
            dld.setListGenerator(1, [p0, p1, pf])
            
        # generate list of 64 entries
        pulseList = []
        for i in range(0, 64):
            p = PulseConfig()
            p.set(i*10, i%12, (i%23)-5, True)
            pulseList.append(p)
            
        dld.setListGenerator(1, pulseList)
        readbackList = dld.getListGenerator(1)
        for i in range(0, 64):
            self.assertEqual(pulseList[i].to_string(), readbackList[i].to_string())
            
            
        # generate list of 64 entries
        pulseList = []
        for i in range(0, 10):
            p = PulseConfig()
            p.set(i*9, i%12, (i%23)-5, True)
            pulseList.append(p)
        
        # test, if we write 0 at the end of the list in memory:
        dld.writeToBus(dld.ADDR_LIST_GEN1_BASE + 4*10, 1234)
        dld.setListGenerator(1, pulseList)
        readbackList = dld.getListGenerator(1)
        for i in range(0, 10):
            self.assertEqual(pulseList[i].to_string(), readbackList[i].to_string())
        # check for the 0 at the end in memory
        self.assertEqual(dld.readFromBus(dld.ADDR_LIST_GEN1_BASE + 4*10), 0)
        
        
        # test channel 2:
        # generate list of 64 entries
        pulseList2 = []
        for i in range(0, 4):
            p = PulseConfig()
            p.set(i*3, i%7, (i%33)-17, True)
            pulseList2.append(p)
        dld.setListGenerator(2, pulseList2)
        readbackList2 = dld.getListGenerator(2)
        for i in range(0, 4):
            self.assertEqual(pulseList2[i].to_string(), readbackList2[i].to_string())
            
        # test if generator 1 has not been altered:
        readbackList = dld.getListGenerator(1)
        for i in range(0, 10):
            self.assertEqual(pulseList[i].to_string(), readbackList[i].to_string())
        # check for the 0 at the end in memory
        self.assertEqual(dld.readFromBus(dld.ADDR_LIST_GEN1_BASE + 4*10), 0)
        
        # test activation of the list generator
        dld.setListGeneratorActive(1, True)
        self.assertEqual(dld.readFromBus(dld.ADDR_LIST_GEN1_BASE + 0x100), 0x01)
        self.assertEqual(dld.isListGeneratorActive(1), True)
        
        dld.setListGeneratorActive(1, False)
        self.assertEqual(dld.readFromBus(dld.ADDR_LIST_GEN1_BASE + 0x100), 0x00)
        self.assertEqual(dld.isListGeneratorActive(1), False)
        
        dld.setListGeneratorActive(2, True)
        self.assertEqual(dld.readFromBus(dld.ADDR_LIST_GEN2_BASE + 0x100), 0x01)
        self.assertEqual(dld.isListGeneratorActive(2), True)
        
        dld.setListGeneratorActive(2, False)
        self.assertEqual(dld.readFromBus(dld.ADDR_LIST_GEN2_BASE + 0x100), 0x00)
        self.assertEqual(dld.isListGeneratorActive(2), False)
        
if __name__ == '__main__':
    unittest.main()


