# RT3D: Real-Time 3D Vehicle Detection in LiDAR Point Cloud for Autonomous Driving
This is repositoy of paper "RT3D: Real-Time 3D Vehicle Detection in LiDAR Point Cloud for Autonomous Driving"

Our implementation are based on the RFCN by YuwenXiong: https://github.com/YuwenXiong/py-R-FCN

And the Caffe should use the Mircosoft brunch :https://github.com/Microsoft/caffe.git

Runtime support: CUDA 8.0, CUDNN-v5

The results on validation set is here: [download](https://drive.google.com/file/d/1ACaar6enyFNsCFPawVu16tyNWQLpXPmU/view?usp=sharing)



## ResNet model 
$ROOT/data/imagenet_models/ResNet-50-deploy.prototxt
$ROOT/data/imagenet_models/ResNet-50-model.caffemodel

## Data
Kitti object detection data should transfer to Pascal VOC style.
$ROOT/data/VOCdevkit2007

## Running
To runnung testing
$ python test_theta_w_l.py --gpu id --img BEVPATH

