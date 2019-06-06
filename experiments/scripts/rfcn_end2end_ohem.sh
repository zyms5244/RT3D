#!/bin/bash
# Usage:
# ./experiments/scripts/rfcn_end2end_ohem.sh GPU NET DATASET [options args to {train,test}_net.py]
# DATASET is either pascal_voc or coco.
#
# Example:
# ./experiments/scripts/rfcn_end2end_ohem.sh 0 ResNet50 pascal_voc \
#   --set EXP_DIR foobar RNG_SEED 42 TRAIN.SCALES "[400, 500, 600, 700]"

set -x
set -e

export PYTHONUNBUFFERED="True"

GPU_ID=$1
NET=$2
EXTRA_ARGS=$3


TRAIN_IMDB="voc_2007_train"
ITERS=200000


LOG="experiments/logs/rfcn_end2end_${NET}_${EXTRA_ARGS}.txt.`date +'%Y%m%d_%H%M%S'`"
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"


time ./tools/train_net.py --gpu ${GPU_ID} \
  --solver models/solver_ohem.prototxt \
  --weights data/imagenet_models/${NET}-model.caffemodel \
  --imdb ${TRAIN_IMDB} \
  --iters ${ITERS} \
  --cfg experiments/cfgs/rfcn_end2end_ohem.yml \
  --suffix ${EXTRA_ARGS}


set +x
NET_FINAL=`tail -n 100 ${LOG} | grep -B 1 "done solving" | grep "Wrote snapshot" | awk '{print $4}'`
set -x