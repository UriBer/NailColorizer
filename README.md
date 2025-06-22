# NailColorizer Lite for Salons 💅

This project deploys a fully functional AI-powered nail color preview app tailored for salons and beauty shops.
It includes:

- 📦 EC2 server running FastAPI (Python) to apply polish via AI
- 🌐 API Gateway (HTTP) to expose a /recolor endpoint
- 🪣 S3 static website hosting with a CloudFront HTTPS layer
- 📲 Static site where users can take/upload a photo and apply a polish color

---

## 🧰 Requirements
- Terraform (v1.0+)
- AWS CLI (configured with credentials)
- Valid EC2 Key Pair (for SSH)

---

## 🚀 Deployment Instructions

### ⏱️ Deployment Time Expectations
**Total deployment time: 5-10 minutes**
- EC2, S3, API Gateway: ~2-3 minutes
- **CloudFront Distribution: ~5-7 minutes** (AWS requirement)
- The script will show progress and wait appropriately

### 1. Customize Variables
Edit your `terraform.tfvars` or provide the key name during apply:
```hcl
key_pair_name = "your-ec2-key"
```

### 2. Prepare UI Files
Ensure the following files exist in your Terraform root directory:
- `index.html` — the main UI (mobile-optimized)
- `main.js` — JavaScript logic for image upload and API call

### 3. Deploy Infrastructure
Run the wrapper script:
```bash
chmod +x deploy_full_stack.sh
./deploy_full_stack.sh
```

This will:
- Initialize and apply Terraform
- Generate `api-info.json`
- Upload static site to S3
- Invalidate CloudFront cache for instant update
- **Wait for CloudFront deployment** (this takes 5-7 minutes)

---

## 🔎 Output
After deployment, Terraform will output:

- `api_url`: API endpoint for recoloring nails
- `website_url`: Public HTTPS site for salons to use

Example:
```txt
API Endpoint: https://xyz123.execute-api.us-east-1.amazonaws.com/recolor
Website: https://d1abcdefgh.cloudfront.net
```

---

## 🎨 Try It Out
Visit the website URL and:
- Choose a polish color
- Take/upload a photo of a hand
- See the polished version in seconds!

---

## 🧼 Cleanup
To destroy all resources:
```bash
terraform destroy
```

## ⚠️ Important Notes
- **CloudFront takes 5-7 minutes to deploy** - this is normal AWS behavior
- The deployment script includes proper error handling and logging
- All deployment logs are saved to `deploy.log`
- The website will be available via HTTPS through CloudFront

Enjoy NailColorizer Lite ✨
