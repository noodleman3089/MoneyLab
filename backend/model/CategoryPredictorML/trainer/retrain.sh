#!/bin/sh
export PYTHONPATH=/usr/src/app/model/CategoryPredictorML:$PYTHONPATH

echo "--- Starting Model Retraining Process --- $(date)"

# redirect stdout & stderr
python /usr/src/app/ml_pipeline/train_model.py >> /var/log/retrain.log 2>&1
python /usr/src/app/ml_pipeline/train_global_model.py >> /var/log/retrain.log 2>&1

echo "--- Retraining process has been completed! --- $(date)"
