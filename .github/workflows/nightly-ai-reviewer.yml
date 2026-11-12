import os
import json
import subprocess
from google import genai
from google.genai import types

def run_ai_code_reviewer():
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY environment variable is missing.")

    client = genai.Client(api_key=api_key)

    # 1. Read security scan results
    scan_report = "{}"
    if os.path.exists("results_json.json"):
        with open("results_json.json", "r") as f:
            scan_report = f.read()

    # 2. Gather Terraform files
    tf_code_context = ""
    for root, dirs, files in os.walk("."):
        if ".git" in root or ".github" in root:
            continue
        for file in files:
            if file.endswith(".tf"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as tf_file:
                    tf_code_context += f"\n--- FILE: {filepath} ---\n" + tf_file.read()

    # 3. Prompt Gemini to analyze and improve security
    prompt = f"""
    You are an expert DevSecOps and Terraform AI Agent. 
    Review the following infrastructure code and security scan report. Identify security vulnerabilities, misconfigurations (especially regarding GCP IAM, encryption, or public exposure), and code quality improvements.

    Security Scan Findings:
    {scan_report}

    Terraform Source Code:
    {tf_code_context}

    Provide your response as a valid JSON object with the following structure:
    {{
      "improvements_made": true,
      "summary": "Description of security fixes applied",
      "files_updated": [
        {{
          "path": "path/to/file.tf",
          "content": "full updated content of the file"
        }}
      ]
    }}
    """

    response = client.models.generate_content(
        model='gemini-3.8-flash',
        contents=prompt,
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            temperature=0.1
        ),
    )

    result = json.loads(response.text)
    
    if result.get("improvements_made"):
        for updated_file in result.get("files_updated", []):
            path = updated_file["path"]
            content = updated_file["content"]
            with open(path, "w") as f:
                f.write(content)
            print(f"Successfully updated {path} with AI security improvements.")
            
        # Configure Git and create a Pull Request branch
        subprocess.run(["git", "config", "--global", "user.name", "AI Nightly Security Agent"])
        subprocess.run(["git", "config", "--global", "user.email", "ai-agent@users.noreply.github.com"])
        
        branch_name = "ai-agent/security-hardening-nightly"
        subprocess.run(["git", "checkout", "-b", branch_name])
        subprocess.run(["git", "add", "."])
        subprocess.run(["git", "commit", "-m", f"🔒 AI Nightly Security Fixes: {result.get('summary')}"])
        subprocess.run(["git", "push", "origin", branch_name, "--force"])

if __name__ == "__main__":
    run_ai_code_reviewer()