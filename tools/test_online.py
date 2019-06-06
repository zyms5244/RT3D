

import _init_paths
from fast_rcnn.config import cfg
from fast_rcnn.test import im_detect
from fast_rcnn.nms_wrapper import nms
from utils.timer import Timer
import matplotlib.pyplot as plt
import numpy as np
import scipy.io as sio
import caffe, os, sys, cv2
import argparse
import math
import scipy.io as sio

CLASSES = ('__background__',
           'car')
save_image = False
debug_info = False


def box_rot(l, w, theta):#this theta is rp(cloce-wise)
    p0 = np.array([[-l/2,l/2,l/2,-l/2],[-w/2,-w/2,w/2,w/2]])
    costheta = math.cos(theta)
    sintheta = math.sin(theta)
    rot = np.array([[costheta,-sintheta],[sintheta,costheta]])
    p1 = np.dot(rot,p0)
    return p1


def vis_detections(im, class_name, dets, bord, thet, fp, thresh=0.5):
    """Draw detected bounding boxes."""
    para_dict={
        'left': 20,
        'right': -20,
        'front': 40,
        'back': 0,
        'resolution': 0.05
    }
    inds = np.where(dets[:, -1] >= thresh)[0]
    if len(inds) == 0:
        return

    im = im[:, :, (2, 1, 0)]
    if save_image:
        fig, ax = plt.subplots(figsize=(12, 12))
        ax.imshow(im, aspect='equal')
    for i in inds:
        bbox = dets[i, :4]
        score = dets[i, -1]
        center = np.array([[(dets[i, 0]+dets[i, 2])/2],[(dets[i, 1]+dets[i, 3])/2]])
        theta = thet[i, 0]
        l = bord[i, 0]
        w = bord[i, 1]
        h = bord[i, 2]
        tz = bord[i, 3]
        p1 = box_rot(l, w, theta)/para_dict['resolution'] + center
        p2 = p1.transpose()

        fp.write("%s %f %f %f %f %f %f %f %f\n" % (class_name,
                                                   para_dict['front']-center[1,0]*para_dict['resolution'],
                                                   para_dict['left']-center[0,0]*para_dict['resolution'],
                                                   tz,theta,l,w,h,score))

        if save_image:

            ax.add_patch(
                plt.Polygon(p2,edgecolor='red',linewidth=2,fill=False)
                )
            ax.add_patch(
                plt.Rectangle((bbox[0], bbox[1]),
                              bbox[2] - bbox[0],
                              bbox[3] - bbox[1], fill=False,
                              edgecolor='yellow', linewidth=2)
                )
            ax.text(bbox[0], bbox[1] - 2,
                    '{:s} {:.3f} height {:.3f} tz {:.3f}'.format(class_name, score, h, tz),
                    bbox=dict(facecolor='blue', alpha=0.5),
                    fontsize=14, color='white')
    if save_image:
        ax.set_title(('{} detections with '
                      'p({} | box) >= {:.1f}').format(class_name, class_name,
                                                      thresh),
                      fontsize=14)
        plt.axis('off')
        plt.tight_layout()
        plt.draw()

def car_detect(net, image_name, fp):

    im_file = image_name
    im = cv2.imread(im_file)
    if im is None:
        return

    # Detect all object classes and regress object bounds
    timer = Timer()
    timer.tic()
    scores, boxes, border, theta = im_detect(net, im)
    timer.toc()
    print ('Detection took {:.3f}s for '
           '{:d} object proposals').format(timer.total_time, boxes.shape[0])

    # Visualize detections for each class
    CONF_THRESH = 0.3
    NMS_THRESH = 0.3
    for cls_ind, cls in enumerate(CLASSES[1:]):
        cls_ind += 1 # because we skipped background
        cls_boxes = boxes[:, 4:8]
        cls_border = border[:, 4:8]
        cls_theta = theta[:, 1:2]
        cls_scores = scores[:, cls_ind]
        dets = np.hstack((cls_boxes,
                          cls_scores[:, np.newaxis])).astype(np.float32)
        keep = nms(dets, NMS_THRESH)
        dets = dets[keep, :]
        bord = cls_border[keep, :]
        thet = cls_theta[keep, :]

        vis_detections(im, cls, dets, bord, thet, fp, thresh=CONF_THRESH)

def parse_args():
    """Parse input arguments."""
    parser = argparse.ArgumentParser(description='Faster R-CNN demo')
    parser.add_argument('--gpu', dest='gpu_id', help='GPU device id to use [0]',
                        default=0, type=int)
    parser.add_argument('--cpu', dest='cpu_mode',
                        help='Use CPU mode (overrides --gpu)',
                        action='store_true')
    parser.add_argument('--img', dest='img_path', help='image path',
                        default='~/kitti_data/kitti_object/testing/encode2_40/birdViewJPG', type=str)
    parser.add_argument('--fig', dest='fig', help='save image',
                        default=False, type=bool)
    parser.add_argument('--debug', dest='debug', help='debug info',
                        default=False, type=bool)
    parser.add_argument('--prototxt', dest='prototxt', help='model prototxt',
                        default='test_agnostic_new', type=str)
    parser.add_argument('--caffemodel', dest='caffemodel', help='model name',
                        default='resnet50_rfcn_ohem_iter_20000trainval', type=str)
    args = parser.parse_args()

    return args

if __name__ == '__main__':
    args = parse_args()
    cfg.TEST.HAS_RPN = True  # Use RPN for proposals
    save_image = args.fig
    debug_info = args.debug

    curdir = os.path.join(os.getcwd(), '..')

    prototxt = os.path.join(curdir, 'models', args.prototxt.split('.')[0] + '.prototxt')
    caffemodelname = args.caffemodel.split('.')[0] + '.caffemodel'
    caffemodel = os.path.join(curdir, 'output', 'rfcn_end2end_ohem', 'voc_2007_train', caffemodelname)
    imageset = os.path.join(curdir, 'data','VOCdevkit2007', 'VOC2007', 'ImageSets')
    output = os.path.join(curdir, 'output')
    
    if not os.path.isfile(caffemodel):
        raise IOError(('{:s} not found.\n').format(caffemodel))

    if args.cpu_mode:
        caffe.set_mode_cpu()
    else:
        caffe.set_mode_gpu()
        caffe.set_device(args.gpu_id)
        cfg.GPU_ID = args.gpu_id
    net = caffe.Net(prototxt, caffemodel, caffe.TEST)

    print '\n\nLoaded network {:s}'.format(caffemodel)

    # Warmup on a dummy image
    im = 128 * np.ones((800, 800, 3), dtype=np.uint8)
    for i in xrange(2):
        _, _, _, _= im_detect(net, im)

    print 'loading testing file lists...'
    with open(os.path.join(imageset, 'Main_online', 'test.txt')) as test_list_file:
        lines = [line.strip() for line in test_list_file.readlines()]


    for line in lines[0:]:
        print line + "detecting ..."
        im_name = os.path.join(args.img_path, line+'.jpg')
        if not os.path.exists(os.path.join(output, 'online'+caffemodelname)):
            os.mkdir(os.path.join(output, 'online'+caffemodelname))
            os.mkdir(os.path.join(output, 'online'+caffemodelname, 'pred'))
            os.mkdir(os.path.join(output, 'online'+caffemodelname, 'data'))

        res_name = os.path.join(output, 'online'+caffemodelname, 'pred', line + '.txt')

        with open(res_name, 'w') as fp:
            car_detect(net, im_name, fp)
            if save_image:
                plt.savefig(os.path.join(output, 'online'+caffemodelname, line +'.jpg'))
                plt.close('all')
    
    ########################################################
    ## transfer coordinator from lidar to camera
    ########################################################
    # cnnresult_dir = os.path.join(output, 'online'+caffemodelname, 'pred')
    # calib_dir = '~/kitti_data/kitti_cloud/testing/calib'
    # kittiresult_dir = os.path.join(output, 'online'+caffemodelname, 'data')
    # eval_list = os.path.join(imageset, 'Main_online', 'test.txt')
    # sio.savemat('../output/mat/online_path_%s.mat' % args.caffemodel,
    #             {'cnnresult_dir':cnnresult_dir,
    #              'calib_dir':calib_dir,
    #              'kittiresult_dir':kittiresult_dir,
    #              'eval_list':eval_list})
    # os.system('matlab -nosplash -nodesktop -r ~/kitti_data/kitti_ral/genKittiTest3D.m')
