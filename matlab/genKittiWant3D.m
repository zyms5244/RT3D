clear all

period = 'test';

if(strcmp(period,'val')==1)
    cnnresult_dir = '/home/jason/didi2017/py-R-FCN/output/resultCar';
    calib_dir = '/home/jason/kitti_cloud/training/calib';
    kittiresult_dir = '/home/jason/kittiLidarToDepth/kittiToVOC/kitti_label_car_val';

    testimg_dir = '/home/jason/kitti_cloud/training/camera/training/image_2';
    
    [testimg_name1] = textread('/home/jason/didi2017/py-R-FCN/data/VOCdevkit2007/VOC2007/ImageSets/Main/val.txt','%s');
    testimg_name = zeros(numel(testimg_name1));
    for t=1:numel(testimg_name1)
        testimg_name(t) = str2num(testimg_name1{t});
    end
    
    outimg_dir = '/home/jason/kittiLidarToDepth/kittiToVOC/output_img';
else
    if(strcmp(period,'test')==1)
        cnnresult_dir = '~/kitti_tracking/py-R-FCN/output/resultObjectCar';
        calib_dir = '~/kitti_tracking/kitti_cloud/testing/calib';
        kittiresult_dir = '~/kitti_tracking/kittiToVOC/kittiobject3D_label_car20180108';
        
        testimg_dir = '~/kitti_tracking/kitti_cloud/testing/camera/testing/image_2';
        
        [testimg_name1] = textread('~/kitti_tracking/py-R-FCN/data/VOC2007/ImageSets/Main/test.txt','%s');
        testimg_name = zeros(numel(testimg_name1), 1);
        for t=1:numel(testimg_name1)
            testimg_name(t) = str2num(testimg_name1{t})-7481;
        end
        
        outimg_dir = '~/kitti_tracking/kittiToVOC/output_img_kittiobject3D20180108';
    end
end

show_img = 0;
save_img = 0;

img_row = 375;
img_col = 1242;

for i=1:numel(testimg_name1)
    clear objects
    objects = cell(0,1);
    
    testimg_name(i)
    
    if(show_img)
        figure(1);
        img_name = sprintf('%s/%06d.png',testimg_dir,testimg_name(i));
        img = imread(img_name);
        imshow(img)
        hold on
    end
    
    cnnresult_name = sprintf('%s/%06d.txt',cnnresult_dir,testimg_name(i));
    [type,tx,ty,tz,ry,carl,carw,carh,score] = textread(cnnresult_name,'%s%f%f%f%f%f%f%f%f');
    intrin = [readCalibration(calib_dir,testimg_name(i),2);0 0 0 1];
    rectify = readCalibration(calib_dir,testimg_name(i),4);
    rectify = reshape(rectify',[3,4]);
    rectify = [rectify;0 0 0 1]';
    trans = [readCalibration(calib_dir,testimg_name(i),5);0 0 0 1];
    R0 = intrin*rectify*trans;
    
    items = length(type);
    index = 1;
    
    for j=1:items
        %score > 0.95
        if(score(j)<0.95)
            continue;
        end
        %get 3D box
        P0 = [-carw(j)/2,-carw(j)/2,carw(j)/2,carw(j)/2,-carw(j)/2,-carw(j)/2,carw(j)/2,carw(j)/2;
            -carl(j)/2,carl(j)/2,carl(j)/2,-carl(j)/2,-carl(j)/2,carl(j)/2,carl(j)/2,-carl(j)/2;
            0,0,0,0,carh(j),carh(j),carh(j),carh(j);
            1,1,1,1,1,1,1,1];
        costheta = cos(ry(j));
        sintheta = sin(ry(j));
        R1 = [costheta sintheta 0 tx(j);
            -sintheta costheta 0 ty(j);
            0 0 1 tz(j);
            0 0 0 1];
        t = trans*[tx(j);ty(j);tz(j);1];
        P1 = R0*R1*P0;
        
        filter1=find(P1(3,:)>0);
        if(isempty(filter1))
            continue;
        end
        
        P = [P1(1,:)./P1(3,:);
            P1(2,:)./P1(3,:)];
        xmin = min(P(1,filter1));
        xmax = max(P(1,filter1));
        ymin = min(P(2,filter1));
        ymax = max(P(2,filter1));
        if(xmax<1||xmin>img_col||ymax<1||ymin>img_row)
            continue;
        end
        if(xmin<1)
            xmin=1;
        end
        if(xmax>img_col)
            xmax=img_col;
        end
        if(ymin<1)
            ymin=1;
        end
        if(ymax>img_row)
            ymax=img_row;
        end
        if(ymax-ymin<25||xmax-xmin<10)
            continue;
        end
        
        objects(index).type='Car';
        objects(index).alpha=ry(j)-atan2(t(1),t(3));
        objects(index).x1=xmin;
        objects(index).x2=xmax;
        objects(index).y1=ymin;
        objects(index).y2=ymax;
        objects(index).l=carl(j);
        objects(index).w=carw(j);
        objects(index).h=carh(j);
        objects(index).t(1)=t(1);
        objects(index).t(2)=t(2);
        objects(index).t(3)=t(3);
        objects(index).ry=ry(j);
        objects(index).score=score(j);
        
        if(show_img)
            figure(1);
            rectangle('Position',[objects(index).x1,objects(index).y1,objects(index).x2-objects(index).x1+1,objects(index).y2-objects(index).y1+1],...
                'LineWidth',3,'EdgeColor','r');
        end
        
        index=index+1;
    end
    
    if(save_img)
        saveas(1,[outimg_dir,'/',testimg_name1{i},'.jpg']);
    end
    
    writeLabels(objects,kittiresult_dir,testimg_name(i));
    
end