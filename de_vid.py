#!/usr/bin/python
import os, shutil
for i in os.listdir('.'):
	f2 = i.replace('VID_', '').replace('FJ', '')
	shutil.move(i, f2)
