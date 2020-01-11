# -*- coding: utf-8 -*-
"""
Created on Fri Jan 10 16:31:04 2020

@author: Lukas

Creates random numbers an calculates the average values using a moving 
average filter 
"""

import random
import numpy as np

BATCH_SIZE = 100
WIDTH = 28
HEIGTH = 28

random_batch = np.ones((BATCH_SIZE,HEIGTH,WIDTH),dtype=np.int16)
average_values = np.zeros((BATCH_SIZE,HEIGTH,WIDTH),dtype=np.int16)


class FIFO:
    """
    Creates a FIFO 
    size: size of fifo
    wrte(data) : writes data into fifo 
    read(): reads data from fifo
    """
    def __init__(self, size):
        self.content = np.zeros(int(size))
        self.size = size
        self.rd_pointer = 0
        self.wr_pointer = 0
    def write(self,data):
        wr_pointer = self.wr_pointer + 1
        if wr_pointer >= self.size:
            wr_pointer = 0
        if wr_pointer == self.rd_pointer:
            print("FIFO FULL",data,wr_pointer)
        else:    
            self.wr_pointer = wr_pointer    
            self.content[wr_pointer] = data            
    def read(self):        
        if self.rd_pointer == self.wr_pointer:
            print("FIFO empty")
        else: 
            data = self.content[self.rd_pointer]
            self.rd_pointer -= 1
            if self.rd_pointer < 0:
                self.rd_pointer = self.size -1    
            return data

for b in range(BATCH_SIZE):
    for h in range(HEIGTH):
        for w in range(WIDTH):
            random_batch[b,h,w] = random.randrange(-255,255)

counter = 0   
av_fifo = FIFO(32)   
average = 0
      
for b in range(BATCH_SIZE):
    for h in range(HEIGTH):
        for w in range(WIDTH):
            av_fifo.write(random_batch[b,h,w])
            average += random_batch[b,h,w]
            counter += 1
            if counter >= 32:
                average -= av_fifo.read()
                average_values[b,h,w] = average/32
                
            
            
            
            
            
