clear

label_dir='./training/label_2';
calib_dir='./training/calib';
calib_label_dir='./training/pred_label';

% parameters
upBound=0.5;
lowBound=-2.5;
maxFront=60;%front-back
maxBack=0;
maxLeft=30;%left-right
maxRight=-maxLeft;
resolution=0.1;

if ~exist(calib_label_dir,'dir')
    mkdir(calib_label_dir);
    
    
    for idx1=0:7480
        if mod(idx1, 20) == 0
            disp(['idx:',num2str(idx1)]);
        end
        
        label=readLabels(label_dir,idx1);
        T_cam_lidar=[readCalibration(calib_dir,idx1,5);0 0 0 1];
        fw=fopen(sprintf('%s/%06d.txt',calib_label_dir,idx1),'wt');
        %img=imread(sprintf('%s/%06d.jpg',image_dir,idx1));
        
        for idx2=1:numel(label)
            pos_cam=[label(idx2).t(1);label(idx2).t(2);label(idx2).t(3);1];
            pos_lidar=T_cam_lidar\pos_cam;
            pos_lidar=pos_lidar(1:3);
            theta=-label(idx2).ry;
            sintheta=abs(sin(theta));
            costheta=abs(cos(theta));
            bbox_lidar=[sintheta costheta;costheta sintheta]*[label(idx2).l;label(idx2).w];
            bbox_lidar_w=bbox_lidar(1);%width;front back;face right
            bbox_lidar_l=bbox_lidar(2);%length;left right
            
            left=int32((maxLeft-(pos_lidar(2)+bbox_lidar_l/2))/resolution);
            right=int32((maxLeft-(pos_lidar(2)-bbox_lidar_l/2))/resolution);
            up=int32((maxFront-(pos_lidar(1)+bbox_lidar_w/2))/resolution);
            down=int32((maxFront-(pos_lidar(1)-bbox_lidar_w/2))/resolution);
            
            if(left<0||right>=800||up<0||down>=800)
                continue;
            end
            
            fprintf(fw,'%s %f %f %f %f %f %f %f %f\n', label(idx2).type, pos_lidar(1),pos_lidar(2),...
                                                   pos_lidar(3),theta,label(idx2).l,label(idx2).w,label(idx2).h,0.99);
            
          
            %%show image
            %draw_rect(img,[left+1,up+1,int32(bbox_lidar_l/0.05),int32(bbox_lidar_w/0.05)],1);
        end
        
        fclose(fw);
    end
    
end