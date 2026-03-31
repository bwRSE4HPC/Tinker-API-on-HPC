import os
import requests
import sys

# Configuration matches the local orchestrator and HPC tunnel
BASE_URL = "http://localhost:8000"
API_KEY = os.environ.get("TINKER_API_KEY", "tml-dummy")
MODEL_NAME = "Qwen/Qwen2.5-0.5B-Instruct"

def check_server_connection():
    """Verifies that the SSH tunnel is active and the SkyRL API is reachable."""
    print(f"Checking connection to Tinker API at {BASE_URL}...")
    try:
        # Ping the root or docs endpoint of the FastAPI server
        response = requests.get(f"{BASE_URL}/docs", timeout=5)
        if response.status_code == 200:
            print("Successfully connected to the HPC compute node!")
        else:
            print(f"Reached the server, but got status code: {response.status_code}")
    except requests.exceptions.ConnectionError:
        print("Connection failed. Ensure local_run.sh is running and the tunnel is open.")
        sys.exit(1)

def main():
    check_server_connection()
    
    print("\n The environment is ready for experiments.")
    print("Below is the template for initializing the Tinker SDK in your ML workflows:\n")
    
    print("-" * 60)
    print(f"""
# 1. Import the Tinker SDK
from tinker import create_lora_training_client

# 2. Initialize the client (triggers SkyRL model loading if not already cached)
client = create_lora_training_client(
    base_url="{BASE_URL}",
    api_key="{API_KEY}",
    model_name="{MODEL_NAME}",
    lora_rank=32  # Set to 0 for full-parameter fine-tuning
)

# 3. Example: Generate a rollout (Sampling) for a logic prompt
prompt = "Explain the philosophical implications of artificial reasoning."

print("Sending sample request to HPC...")
# Note: Syntax may vary slightly depending on the specific tinker-cookbook version
rollouts = client.sample(
    prompts=[prompt],
    max_tokens=256,
    temperature=0.7
)

print(rollouts)
""")
    print("-" * 60)
    print("\nTo execute full training loops (like GRPO or Supervised Fine-Tuning),")
    print("please refer to the tinker-cookbook recipes.")

if __name__ == "__main__":
    main()
