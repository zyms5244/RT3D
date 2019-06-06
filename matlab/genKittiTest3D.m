clear all


% cnnresult_dir = '~/kitti_data/kitti_ral/RTFCN/output/resnet50_rfcn_ohem_iter_20000trainval_itersize_8.caffemodel/';
% calib_dir = '~/kitti_data/kitti_cloud/training/calib';
% kittiresult_dir = '~/kitti_data/kitti_ral/RTFCN/output/iter8';
% eval_list = '~/kitti_data/kitti_ral/RTFCN/data/VOCdevkit2007/VOC2007/ImageSets/Main/test.txt';
% for myi =1:20
% matpath = sprintf('~/kitti_data/rt3d/output/mat/eval_path_resnet50_rfcn_ohem_iter_%d0000online85_max200k.mat', myi)
% load(matpath)
load('~/kitti_data/rt3d/output/mat/eval_path_resnet50_rfcn_ohem_iter_30000online85_max200k.mat');
[testimg_name1] = textread(eval_list,'%s');
testimg_name = zeros(numel(testimg_name1), 1);
for t=1:numel(testimg_name1)
    testimg_name(t) = str2num(testimg_name1{t}(1:6));
end


show_img = 0;
save_img = 0;

img_row = 375;
img_col = 1242;

for i=1:numel(testimg_name1)
    clear objects
    objects = cell(0,1);
    
    testimg_name(i)
   
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
        if(score(j)<0.6)
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
        if(ymax-ymin<20||xmax-xmin<3)
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
% end
