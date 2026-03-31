#!/bin/bash
#SBATCH --job-name=setup_skyrl
#SBATCH --partition=cpuonly
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=2
#SBATCH --output=setup_skyrl.log

cd $HOME/TinkerOnBwHPC/SkyRL

echo "Pulling Apptainer image..."
apptainer pull skyrl-fsdp.sif docker://novaskyai/skyrl-train-ray-2.51.1-py3.12-cu12.8

echo "Image pulled. Caching Python dependencies..."
apptainer exec --bind .:/workspace --pwd /workspace skyrl-fsdp.sif uv sync --extra tinker --extra fsdp

echo "Setup complete!"
