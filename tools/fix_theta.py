#coding=utf-8
import cv2
import numpy as np  

para_dict={
    'left': 30,
    'right': -30,
    'front': 60,
    'back': 0,
    'resolution': 0.1
}

bbox_path = '/home/ans/kitti_data/kitti_ral/RTFCN/tools/bbox.txt'
img_path = '/home/ans/kitti_data/kitti_ral/training/encode2_r1e-1/birdViewJPG/007341.jpg'


img = cv2.imread(img_path)

class CarBox:
	def __init__(self,x1,y1,x2,y2):
		self.x1 = x1
		self.y1 = y1
		self.x2 = x2
		self.y2 = y2
	def getpred(self,x,y,tz,theta,l,w,h,score):
		self.x = x
		self.y = y
		self.tz = tz
		self.theta = theta
		self.l = l
		self.w = w
		self.h = h
		self.score = score


def loadprebox(line):
	items = line.split()
	if items[0] == "car" or items[0] == "Car":
		x = float(items[1])
		y = float(items[2])
		tz = float(items[3])
		theta = float(items[4])
		l = float(items[5])
		w = float(items[6])
		h = float(items[7])
		score = float(items[8])
	return CarBox(x,y,tx,theta,l,w,h,socre)

def loadbevbox(line):
	items = line.split()

	items = [int(item.split('.')[0]) for item in items]
	t = 5
	return CarBox(items[1]-t, items[0]-t, items[3]+t, items[2]+t)

with open(bbox_path) as f:
	lines = f.readlines()
	bvboxs = [loadbevbox(line) for line in lines]

	for i,bbox in enumerate(bvboxs[0:]):
		imgcrop = img[bbox.x1:bbox.x2, bbox.y1:bbox.y2]
		# imgcrop = cv2.GaussianBlur(imgcrop,(3,3),0)
		# grayimg = cv2.cvtColor(imgcrop, cv2.COLOR_BGR2GRAY) 
		edges = cv2.Canny(imgcrop, 50, 150, apertureSize = 3)
		minLineLength = 15
		maxLineGap = 15
		dlines = cv2.HoughLines(edges,1,np.pi/180,5,minLineLength,maxLineGap)
		# dlines = cv2.HoughLinesP(edges,1,np.pi/180,5,minLineLength,maxLineGap)
		if dlines is not None:
			print dlines
			for x1,y1,x2,y2 in dlines[0]:
			 	cv2.line(imgcrop,(x1,y1),(x2,y2),(0,255,0),1)
		cv2.imshow('edges%d' % i, edges)
		cv2.imshow(str(i), imgcrop)
	cv2.waitKey(0)
	cv2.destroyAllWindows()
		 	




# img = cv2.GaussianBlur(img,(3,3),0)
# edges = cv2.Canny(img, 50, 150, apertureSize = 3)
# cv2.imshow('edges', edges)
# lines = cv2.HoughLines(edges,1,np.pi/180,118)
# result = img.copy()

# #经验参数
# minLineLength = 200
# maxLineGap = 15
# lines = cv2.HoughLinesP(edges,1,np.pi/180,80,minLineLength,maxLineGap)
# for x1,y1,x2,y2 in lines[0]:
# 	cv2.line(img,(x1,y1),(x2,y2),(0,255,0),2)

# cv2.imshow('Result', img)
# cv2.waitKey(0)
# cv2.destroyAllWindows()