# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.

import sys

from PyQt5.QtWidgets import QApplication, QWidget, QPushButton, QVBoxLayout, QTextBrowser
from PyQt5.QtCore import *
from PyQt5.QtGui import *

# from tidevice.__main__ import *
from tidevice._usbmux import *


def print_hi(name):
    # Use a breakpoint in the code line below to debug your script.
    print(f'Hi, {name}')  # Press ⌘F8 to toggle the breakpoint.

    um = Usbmux()
    list = um.device_list()
    print(list)


class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        device_list_button = QPushButton()
        device_list_button.setText('获取设备列表')
        device_list_button.move(100, 100)
        device_list_button.resize(50, 60)
        device_list_button.clicked.connect(self.clickAction)
        layout.addWidget(device_list_button)

        self.text_browser = QTextBrowser()
        self.text_browser.resize(50, 400)
        layout.addWidget(self.text_browser)

        self.setLayout(layout)

    def clickAction(self):
        print("我被点击了")

        um = Usbmux()
        list = um.device_list()

        self.text_browser.setText(str(list))


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    print_hi('PyCharm')

    app = QApplication(sys.argv)
    w = MainWindow()
    w.resize(1000, 600)
    w.move(300, 300)
    w.setWindowTitle('我是性能猫')
    w.show()

    # 进入程序的主循环
    sys.exit(app.exec_())


def test():
    pass


# See PyCharm help at https://www.jetbrains.com/help/pycharm/
