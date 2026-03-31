#!/bin/bash

if [ ! -f "config.env" ]; then
    cp config-template.env config.env
    echo "config.env created, please fill in your details."
    exit 1
fi

source config.env

if [[ "$HPC_USER" == "your_username_here" || "$HPC_PROJECT" == "your_project_id_here" ]]; then
    echo "Error: Please update config.env with your actual HPC username and project ID."
    exit 1
fi

REMOTE_BASE="/home/${HPC_PROJECT}/${HPC_USER}/TinkerOnBwHPC"
REMOTE_SKYRL_DIR="${REMOTE_BASE}/SkyRL"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REMOTE_JOB_DIR="${REMOTE_BASE}/setup_${TIMESTAMP}"
SSH_SOCKET="/tmp/tinker_hpc_${HPC_USER}_setup.sock"

echo "========================================================"
echo "Starting Tinker-on-HPC Setup for ${HPC_USER}..."
echo "========================================================"

echo "Please authenticate with your HPC 2FA..."
ssh -M -S ${SSH_SOCKET} -fN ${HPC_USER}@${HPC_HOST}

if [ $? -ne 0 ]; then
    echo "Failed to establish the Master SSH connection. Exiting."
    exit 1
fi

echo "Creating directory structure on HPC..."
ssh -S ${SSH_SOCKET} ${HPC_USER}@${HPC_HOST} "mkdir -p ${REMOTE_SKYRL_DIR} ${REMOTE_JOB_DIR}"

echo "Transferring toolkit files to HPC..."
scp -o "ControlPath=${SSH_SOCKET}" hpc_setup.sbatch ${HPC_USER}@${HPC_HOST}:${REMOTE_JOB_DIR}/

echo "Cloning the SkyRL repository and submitting setup job..."
ssh -S ${SSH_SOCKET} ${HPC_USER}@${HPC_HOST} "
if [ ! -d '${REMOTE_SKYRL_DIR}/.git' ]
then
    git clone --depth 1 https://github.com/NovaSky-AI/SkyRL.git ${REMOTE_SKYRL_DIR}
fi
cd ${REMOTE_JOB_DIR}
sbatch --partition=${SETUP_PARTITION} hpc_setup.sbatch
"

echo "Closing Master SSH Connection..."
ssh -S ${SSH_SOCKET} -O exit ${HPC_USER}@${HPC_HOST} 2>/dev/null

echo "========================================================"
echo "Setup initiated in the background!"
echo "The cluster is now downloading the image and dependencies."
echo "Check progress by running:"
echo "  > ssh ${HPC_USER}@${HPC_HOST} 'squeue -u ${HPC_USER}'"
echo "  > ssh ${HPC_USER}@${HPC_HOST} 'tail -F ${REMOTE_JOB_DIR}/setup_skyrl.log'"
echo "========================================================"
