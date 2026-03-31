#!/bin/bash

source config.env

REMOTE_BASE="/home/${HPC_PROJECT}/${HPC_USER}/TinkerOnBwHPC"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REMOTE_JOB_DIR="${REMOTE_BASE}/run_${TIMESTAMP}"
SSH_SOCKET="/tmp/tinker_hpc_${HPC_USER}_master.sock"

echo "========================================================"
echo "Starting Tinker API orchestration on HPC..."
echo "========================================================"

echo "Please authenticate with your HPC 2FA..."
ssh -M -S ${SSH_SOCKET} -fN ${HPC_USER}@${HPC_HOST}

if [ $? -ne 0 ]; then
    echo "Failed to establish the Master SSH connection. Exiting."
    exit 1
fi
echo "Master SSH connection established!"

echo "Preparing run directory..."
ssh -S ${SSH_SOCKET} ${HPC_USER}@${HPC_HOST} "mkdir -p ${REMOTE_JOB_DIR}"

echo "Transferring run scripts..."
scp -o "ControlPath=${SSH_SOCKET}" config.env hpc_run.sbatch ${HPC_USER}@${HPC_HOST}:${REMOTE_JOB_DIR}/

echo "Submitting job to Slurm..."
SUBMIT_OUTPUT=$(ssh -S ${SSH_SOCKET} ${HPC_USER}@${HPC_HOST} "
cd ${REMOTE_JOB_DIR}
sbatch --partition=${RUN_PARTITION} --gres=gpu:${GPU_COUNT} hpc_run.sbatch
")
JOB_ID=$(echo $SUBMIT_OUTPUT | awk '{print $4}')

if [[ -z "$JOB_ID" ]]; then
    echo "Failed to submit job to HPC."
    ssh -S ${SSH_SOCKET} -O exit ${HPC_USER}@${HPC_HOST} 2>/dev/null
    exit 1
fi
echo "Job submitted successfully! Job ID: $JOB_ID"

cleanup() {
    # This method cancels the job when this script is stopped.

    # Prevent the trap from triggering twice
    trap - SIGINT EXIT

    echo ""
    echo "Caught termination signal. Cleaning up..."

    if [[ -n "$TUNNEL_PID" ]]; then
        echo "Closing local SSH tunnel..."
        kill $TUNNEL_PID 2>/dev/null
    fi

    echo "Canceling HPC Slurm Job..."
    ssh -S ${SSH_SOCKET} ${HPC_USER}@${HPC_HOST} "scancel $JOB_ID"

    echo "Closing Master SSH Connection..."
    ssh -S ${SSH_SOCKET} -O exit ${HPC_USER}@${HPC_HOST} 2>/dev/null

    echo "Cleanup complete. Resources freed."
    exit 0
}
trap cleanup SIGINT EXIT

echo "Waiting for Slurm allocation (this might take a minute)..."
COMPUTE_NODE=""

while true; do
    STATUS=$(ssh -S ${SSH_SOCKET} ${HPC_USER}@${HPC_HOST} "squeue -j $JOB_ID -h -o '%t %N'")
    STATE=$(echo $STATUS | awk '{print $1}')
    NODE=$(echo $STATUS | awk '{print $2}')

    if [[ "$STATE" == "R" ]]; then
        COMPUTE_NODE=$NODE
        echo "Job is RUNNING on compute node: $COMPUTE_NODE"
        break
    elif [[ "$STATE" == "C" || "$STATE" == "CD" || "$STATE" == "F" || "$STATE" == "TO" ]]; then
        echo "Job failed, timed out, or was canceled."
        exit 1
    fi
    sleep 5
done

echo "Establishing SSH tunnel: Localhost:$LOCAL_PORT -> $COMPUTE_NODE:$REMOTE_PORT..."
ssh -S ${SSH_SOCKET} -N -L ${LOCAL_PORT}:${COMPUTE_NODE}:${REMOTE_PORT} ${HPC_USER}@${HPC_HOST} &
TUNNEL_PID=$!

echo "========================================================"
echo "Tinker API is starting up on the compute node!"
echo "Point your local Python code to: http://localhost:${LOCAL_PORT}"
echo "Press Ctrl+C to terminate the server and exit."
echo "========================================================"

ssh -S ${SSH_SOCKET} ${HPC_USER}@${HPC_HOST} "tail -F ${REMOTE_JOB_DIR}/tinker_server.log"
