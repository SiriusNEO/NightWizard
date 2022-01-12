import serial
ser = serial.Serial('/dev/ttyS4') # open serial port
print(ser.name) # check which port was really used
ser.write(b'serail port on wsl \n') # write a string
s = ser.readline()
print(s)
ser.close()