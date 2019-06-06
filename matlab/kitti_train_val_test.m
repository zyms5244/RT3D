%%
%该代码根据已生成的xml，制作VOC2007数据集中的trainval.txt;train.txt;test.txt和val.txt
%trainval占总数据集的50%，test占总数据集的50%；train占trainval的50%，val占trainval的50%；
%上面所占百分比可根据自己的数据集修改，如果数据集比较少，test和val可少一些
%%
%注意修改下面四个值
xmlfilepath='~/kitti_data/rt3d/data/VOCdevkit2007/VOC2007/Annotations/';
txtsavepath='~/kitti_data/rt3d/data/VOCdevkit2007/VOC2007/ImageSets/Main_online/';
trainval_percent=1.0;%trainval占整个数据集的百分比，剩下部分就是test所占百分比
train_percent=0.85;%train占trainval的百分比，剩下部分就是val所占百分比

xmlfile=dir(xmlfilepath);
numOfxml=length(xmlfile)-2;

trainval=sort(randperm(numOfxml,floor(numOfxml*trainval_percent)));
test=sort(setdiff(1:numOfxml,trainval));

trainvalsize=length(trainval);%trainval的大小
train=sort(trainval(randperm(trainvalsize,floor(trainvalsize*train_percent))));
val=sort(setdiff(trainval,train));

if (~exist('./CarBirdVOCdevkit2007/VOC2007/ImageSets/Main/'))
    mkdir('./CarBirdVOCdevkit2007/VOC2007/ImageSets/Main/');
end

ftrainval=fopen([txtsavepath 'trainval.txt'],'w');
ftest=fopen([txtsavepath 'test.txt'],'w');
ftrain=fopen([txtsavepath 'train.txt'],'w');
fval=fopen([txtsavepath 'val.txt'],'w');


for i=1:numOfxml
    if ismember(i,trainval)
        fprintf(ftrainval,'%s\n',xmlfile(i+2).name(1:end-4));
        if ismember(i,train)
            fprintf(ftrain,'%s\n',xmlfile(i+2).name(1:end-4));
        else
            fprintf(fval,'%s\n',xmlfile(i+2).name(1:end-4));
        end
    else
        fprintf(ftest,'%s\n',xmlfile(i+2).name(1:end-4));
    end
end
fclose(ftrainval);
fclose(ftrain);
fclose(fval);
fclose(ftest);