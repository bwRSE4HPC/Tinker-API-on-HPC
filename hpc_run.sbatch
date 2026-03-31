#!/bin/bash
#SBATCH --job-name=tinker_api
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --gres=gpu:4
#SBATCH --partition=dev_accelerated
#SBATCH --output=tinker_server.log

source config.env

cd $HOME/TinkerOnBwHPC/SkyRL

apptainer exec --nv --bind .:/workspace --pwd /workspace skyrl-fsdp.sif uv run --extra tinker --extra fsdp -m skyrl.tinker.api --base-model "$BASE_MODEL" --backend fsdp
