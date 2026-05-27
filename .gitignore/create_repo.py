import os
import subprocess
import requests

# --- CONFIGURATION ---
# Replace this with your actual GitHub token, or set it as an environment variable
GITHUB_TOKEN = "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"
REPO_NAME = "CSC302 Project"  # The name you want for your GitHub repo
PRIVATE = False                      # Set to False if you want a public repo
# ---------------------

def create_github_repo(token, repo_name, is_private):
    """Creates a remote repository on GitHub using the REST API."""
    url = "https://api.github.com/user/repos"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    data = {
        "name": repo_name,
        "private": is_private,
        "auto_init": False # We will initialize it locally ourselves
    }
    
    print(f"🔄 Creating GitHub repository '{repo_name}'...")
    response = requests.post(url, json=data, headers=headers)
    
    if response.status_code == 201:
        repo_data = response.json()
        print(f"✅ Successfully created remote repository!")
        return repo_data['ssh_url']  # Or use 'clone_url' for HTTPS
    else:
        print(f"❌ Failed to create repository: {response.status_code}")
        print(response.json())
        return None

def initialize_local_git(remote_url):
    """Initializes a local git repo and pushes the initial commit to GitHub."""
    print("🔄 Initializing local Git repository and pushing...")
    try:
        # Create a dummy README if it doesn't exist so there's something to commit
        if not os.path.exists("README.md"):
            with open("README.md", "w") as f:
                f.write(f"# {REPO_NAME}\nCreated automatically via Python.")

        # Run Git commands via terminal
        subprocess.run(["git", "init"], check=True)
        subprocess.run(["git", "add", "."], check=True)
        subprocess.run(["git", "commit", "-m", "Initial commit from Python script"], check=True)
        subprocess.run(["git", "branch", "-M", "main"], check=True)
        subprocess.run(["git", "remote", "add", "origin", remote_url], check=True)
        subprocess.run(["git", "push", "-u", "origin", "main"], check=True)
        
        print("🚀 Local files successfully pushed to GitHub!")
    except subprocess.CalledProcessError as e:
        print(f"❌ Git automation failed: {e}")

if __name__ == "__main__":
    # 1. Create the repo on GitHub
    ssh_url = create_github_repo(GITHUB_TOKEN, REPO_NAME, PRIVATE)
    
    # 2. If successful, initialize local git and push
    if ssh_url:
        initialize_local_git(ssh_url)