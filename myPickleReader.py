# myPickleReader.py

import numpy as np

Tlast = None
Alast = None

def load(fName):
    global Alast, Tlast
    AT = np.load(fName,allow_pickle=True)
    if len(AT)==2:
        Ao = AT[0]
        To = AT[1]
        A = np.zeros((len(Ao),len(Ao[0]),len(Ao[0][0])),np.uint8)
        T = np.zeros((len(Ao),))
        for i in range(len(Ao)):
            for j in range(len(Ao[0])):
                A[i,j,:] = Ao[i][j]
            T[i] = To[i]
        Alast = A
        Tlast = T
        return A,T
    else:
        return AT

def GetLastA():
    return Alast

def GetLastAflat():
    return Alast.reshape((Alast.size,))

def GetSizeA():
    return Alast.shape

def GetLastT():
    return Tlast

if __name__ == '__main__':
    f = r'C:\Users\stijn.helsen\Documents\bala\meas\optFlow\testFrames8_AT.npy'
    A,T = load(f)
    
    print(GetLastAflat().shape)
