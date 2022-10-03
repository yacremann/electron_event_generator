import sys

from PySide2.QtUiTools import QUiLoader

from PySide2.QtWidgets import QApplication, QWidget, QErrorMessage

from PySide2.QtCore import QFile
import glob
from DldSimulator import *

class Gui(QWidget):
    def __init__(self):
        super().__init__()
        self.connect()
        loader = QUiLoader()
        self.window = loader.load('gui.ui', None)
        self.window.show()
        
        self.window.start_interval_input.valueChanged.connect(self.setInterval)
        self.window.ext_start_checkbox.stateChanged.connect(self.setExtStartCheckbox)
        self.window.number_active_spectrum_generator.valueChanged.connect(self.setNumberOfSpectrumGenerator)
        self.window.enable_generator_list_1.stateChanged.connect(self.SetListGenerator)
        self.window.enable_generator_list_2.stateChanged.connect(self.SetListGenerator)
        #self.window.set_list_electron_1.clicked.connect(self.setListElectron1)
        #self.window.set_list_electron_2.clicked.connect(self.setListElectron2)
        
        #self.window.check_electron.clicked.connect(self.getListGenerator)
        # now we do it automatically:
        # self.getListGenerator()
        self.setListElectron1()
        self.setListElectron2()
        
        
        self.window.t0_1.valueChanged.connect(self.setListElectron1)
        self.window.x_axis_1.valueChanged.connect(self.setListElectron1)
        self.window.y_axis_1.valueChanged.connect(self.setListElectron1)
        self.window.t0_2.valueChanged.connect(self.setListElectron2)
        self.window.x_axis_2.valueChanged.connect(self.setListElectron2)
        self.window.y_axis_2.valueChanged.connect(self.setListElectron2)
        
        
        self.updateInterval()
        self.updateExtStartCheckbox()
        self.updateNumberOfSpectrumGenerator()
        self.readActiveListGenerator()
        
        
        
        
    def displayError(self, message):
        em = QErrorMessage(self.window)
        em.showMessage(message)
        
    def connect(self):
        tty = glob.glob("/dev/ttyUSB*")[1]      #depending on connected USB you might 
                                                #need to change which of the USB you take
        self.dld = DldSimulator(tty)
        #self.PulseConfig = PulseConfig()
        
    def setInterval(self):
        value = self.window.start_interval_input.value()
        try:
            self.dld.setInternalStartInterval(value)
        except Exception as exc:
            self.displayError(exc.args[0])
        self.updateInterval()
    
    def updateInterval(self):
        self.window.start_interval_input.setValue(self.dld.getInternalStartInterval())
        
    def setExtStartCheckbox(self):
        value = self.window.ext_start_checkbox.isChecked()
        self.dld.useExternalStart(value)
        self.updateExtStartCheckbox()
        
    def updateExtStartCheckbox(self):
        self.window.ext_start_checkbox.setChecked(self.dld.isExternalStart())
        
    def setNumberOfSpectrumGenerator(self):
        value = self.window.number_active_spectrum_generator.value()
        print(value)
        try:
            self.dld.setActiveSpectrumGenerators(value)
        except Exception as exc:
            self.displayError(exc.args[0])
        self.updateNumberOfSpectrumGenerator()
        
    def updateNumberOfSpectrumGenerator(self):
        self.window.number_active_spectrum_generator.setValue(self.dld.getActiveSpectrumGenerators())
        
    def SetListGenerator(self):
        value1 = self.window.enable_generator_list_1.isChecked()
        value2 = self.window.enable_generator_list_2.isChecked()
        self.dld.setListGeneratorActive(1, value1)
        self.dld.setListGeneratorActive(2, value2)
        self.updateExtStartCheckbox()
    
    def readActiveListGenerator(self):
        self.window.enable_generator_list_1.setChecked(self.dld.isListGeneratorActive(1))
        self.window.enable_generator_list_2.setChecked(self.dld.isListGeneratorActive(2))
        
    def setListElectron1(self):
        p = PulseConfig()
        p.t0 = self.window.t0_1.value()
        p.x  = self.window.x_axis_1.value()
        p.y  = self.window.y_axis_1.value()
        electron = [p]
        try:
            self.dld.setListGenerator(1, electron)
        except Exception as exc:
            self.displayError(exc.args[0])
    
    def setListElectron2(self):
        p = PulseConfig()
        p.t0 = self.window.t0_2.value()
        p.x  = self.window.x_axis_2.value()
        p.y  = self.window.y_axis_2.value()
        p.active = True
        electron = [p]
        try:
            self.dld.setListGenerator(2, electron)
        except Exception as exc:
            self.displayError(exc.args[0])

    def getListGenerator(self):
        #value1 = PulseConfig()
        #value2 = PulseConfig()
        try:
            value1 = self.dld.getListGenerator(1)[0]
        except Exception as exc:
            self.displayError(exc.args[0])
        try:
            value2 = self.dld.getListGenerator(2)[0]
        except Exception as exc:
            self.displayError(exc.args[0])
        
        #print('channel1')
        #print('x = ',  value1.x)
        #print('y = ',  value1.y)
        #print('t0 = ', value1.t0)
        #print('status = ', value1.active)
        #print("channel2")
        #print('x = ',  value2.x)
        #print('y = ',  value2.y)
        #print('t0 = ', value2.t0)
        #print('status = ', value2.active)
        
        
if __name__ == "__main__":
    app = QApplication([])
    gui = Gui()
    #print(window.start_interval_input.setValue(123))

    #sys.exit(app.exec_())
    sys.exit(app.exec_())

