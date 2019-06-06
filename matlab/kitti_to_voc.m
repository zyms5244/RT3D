function [ output_args ] = kitti_to_voc( kitti_label_dir_prefix, idx )

kitti_label_dir=sprintf('%s/%06d.txt',kitti_label_dir_prefix,idx);
% image_dir=sprintf('%s/%06d.jpg',image_dir_prefix,idx);

[type,left,up,right,down,ry,carl,carw,carh,tz] = textread(kitti_label_dir,'%s%d%d%d%d%f%f%f%f%f');
items = length(type);
foldername = 'VOC2007';
img_w = '600';
img_h = '600';
img_d = '3';

output_args=0;

if(items==0)
    return;
end

serial_num = num2str(idx,'%06d');
xmlFileName = ['CarBirdVOCdevkit2007/VOC2007/Annotations/', serial_num, '.xml'];

%xml
Createnode=com.mathworks.xml.XMLUtils.createDocument('annotation');
Root=Createnode.getDocumentElement;%root
node=Createnode.createElement('folder');
node.appendChild(Createnode.createTextNode(sprintf('%s',foldername)));
Root.appendChild(node);
node=Createnode.createElement('filename');
node.appendChild(Createnode.createTextNode(sprintf('%s',[serial_num,'.jpg'])));
Root.appendChild(node);
source_node=Createnode.createElement('source');
Root.appendChild(source_node);
node=Createnode.createElement('database');
node.appendChild(Createnode.createTextNode(sprintf('Cyc BirdView Database')));
source_node.appendChild(node);
node=Createnode.createElement('annotation');
node.appendChild(Createnode.createTextNode(sprintf('VOC2007')));
source_node.appendChild(node);

node=Createnode.createElement('image');
node.appendChild(Createnode.createTextNode(sprintf('flickr')));
source_node.appendChild(node);

node=Createnode.createElement('flickrid');
node.appendChild(Createnode.createTextNode(sprintf('NULL')));
source_node.appendChild(node);
owner_node=Createnode.createElement('owner');
Root.appendChild(owner_node);
node=Createnode.createElement('flickrid');
node.appendChild(Createnode.createTextNode(sprintf('NULL')));
owner_node.appendChild(node);

node=Createnode.createElement('name');
node.appendChild(Createnode.createTextNode(sprintf('lsc')));
owner_node.appendChild(node);
size_node=Createnode.createElement('size');
Root.appendChild(size_node);

node=Createnode.createElement('width');
node.appendChild(Createnode.createTextNode(sprintf('%s',img_w)));
size_node.appendChild(node);

node=Createnode.createElement('height');
node.appendChild(Createnode.createTextNode(sprintf('%s',img_h)));
size_node.appendChild(node);

node=Createnode.createElement('depth');
node.appendChild(Createnode.createTextNode(sprintf('%s',img_d)));
size_node.appendChild(node);

node=Createnode.createElement('segmented');
node.appendChild(Createnode.createTextNode(sprintf('%s','0')));
Root.appendChild(node);


for i = 1 : items
    
    if(strcmp(type{i},'Car')~=1)
        continue;
    end
    obs='car';
    
    %     obs='';
    %     if(strcmp(type{i},'Car')==1)
    %         obs='car';
    %     else
    %         if(strcmp(type{i},'Pedestrian')==1)
    %             obs='ped';
    %         else
    %             if(strcmp(type{i},'Cyclist')==1)
    %                 obs='cyc';
    %             else
    %                 continue;
    %             end
    %         end
    %     end
    
    output_args=output_args+1;
    
    xmin=left(i);
    ymin=up(i);
    xmax=right(i);
    ymax=down(i);
    rot_y=ry(i);
    car_l=carl(i);
    car_w=carw(i);
    car_h=carh(i);
    t_z=tz(i);
    
    
    %write xml
    object_node=Createnode.createElement('object');
    Root.appendChild(object_node);
    node=Createnode.createElement('name');
    node.appendChild(Createnode.createTextNode(obs));
    object_node.appendChild(node);
    
    node=Createnode.createElement('pose');
    node.appendChild(Createnode.createTextNode(sprintf('%s','Unspecified')));
    object_node.appendChild(node);
    
    node=Createnode.createElement('truncated');
    node.appendChild(Createnode.createTextNode(sprintf('%s','0')));
    object_node.appendChild(node);
    
    node=Createnode.createElement('difficult');
    node.appendChild(Createnode.createTextNode(sprintf('%s','0')));
    object_node.appendChild(node);
    
    bndbox_node=Createnode.createElement('bndbox');
    object_node.appendChild(bndbox_node);
    
    node=Createnode.createElement('xmin');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(xmin))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('ymin');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(ymin))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('xmax');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(xmax))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('ymax');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(ymax))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('ry');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(rot_y))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('carl');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(car_l))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('carw');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(car_w))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('carh');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(car_h))));
    bndbox_node.appendChild(node);
    
    node=Createnode.createElement('tz');
    node.appendChild(Createnode.createTextNode(sprintf('%s',num2str(t_z))));
    bndbox_node.appendChild(node);
    
end

if(output_args~=0)
%     voc_bird_file = ['CarBirdVOCdevkit2007/VOC2007/JPEGImages/', serial_num, '.jpg'];
%     copyfile(image_dir, voc_bird_file);
    xmlwrite(xmlFileName,Createnode);
end

end

