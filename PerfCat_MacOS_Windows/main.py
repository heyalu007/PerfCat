# This is a sample Python script.

# Press ⌃R to execute it or replace it with your code.
# Press Double ⇧ to search everywhere for classes, files, tool windows, actions, and settings.

import sys
from PyQt5.QtWidgets import QApplication, QWidget, QPushButton

# from tidevice.__main__ import *
from tidevice._usbmux import *

def print_hi(name):
    # Use a breakpoint in the code line below to debug your script.
    print(f'Hi, {name}')  # Press ⌘F8 to toggle the breakpoint.

    um = Usbmux()
    list = um.device_list()
    print(list)


# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    print_hi('PyCharm')

    app = QApplication(sys.argv)
    w = QWidget()
    w.resize(1000, 600)
    w.move(300, 300)
    w.setWindowTitle('我是性能猫')
    w.show()

    device_list_button = QPushButton()
    device_list_button.setText('获取设备列表')
    device_list_button.move(100, 100)
    # device_list_button.clicked().connect(test)

    # 进入程序的主循环
    sys.exit(app.exec_())


def test():
    pass


# See PyCharm help at https://www.jetbrains.com/help/pycharm/
