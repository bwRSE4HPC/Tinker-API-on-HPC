```markdown

# 🚧  This project is currently under construction and untested. 🚧


# Tinker API on bwHPC - Setup and Execution Guide

This repository contains the orchestration scripts to deploy and use the SkyRL Tinker API on the HPC HPC cluster using Apptainer and Slurm. It establishes a secure SSH tunnel, allowing local execution of Tinker SDK scripts against the compute nodes.

## Prerequisites
- Active HPC account and bwHPC project workspace.
- Local Unix-like environment (Linux, macOS, or WSL) with bash and SSH configured.
- Python environment with the `tinker` SDK installed.

## Setup Instructions

### Configure the Environment
`cp config-template.env config.env`
 and update `HPC_USER` and `HPC_PROJECT` with your specific credentials.

###  Run the Initialization Script
Execute the local setup script from your terminal:
`./local_setup.sh`

This script will:
- Create the necessary directory structure on HPC.
- Transfer the required Slurm and bash scripts.
- Submit a background job to the `cpuonly` partition to build the Apptainer image and cache Python dependencies.

## Usage Instructions

### Start the Server and Tunnel
Run the orchestration script:
`./local_run.sh`

This script submits the GPU job via Slurm, polls the queue for the allocated compute node, establishes a local port forward (default: 8000), and tails the remote logs.

Wait until the terminal outputs "Uvicorn running on [http://0.0.0.0:8000](http://0.0.0.0:8000)".

### Execute Client Code
In a separate terminal, run your ML workloads or the provided example:
`python client_example.py`

### Teardown
When you are finished, return to the terminal running `./local_run.sh` and press `Ctrl+C`. The script will automatically trigger a cleanup function to cancel the Slurm job and terminate the SSH tunnel, freeing the HPC resources.
