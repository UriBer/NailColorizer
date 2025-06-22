# NailColorizer Lite (EC2 + FastAPI + API Gateway)

This project sets up a full AWS deployment of a nail recoloring app using:
- EC2 with FastAPI + Python (rembg + OpenCV)
- S3 buckets for input/output images
- API Gateway (HTTP) as a proxy to EC2
- Terraform-managed infrastructure

---

## 📦 Components

| Component | Purpose |
|----------|---------|
| EC2 t3.micro | Hosts the FastAPI app on port 8000 |
| API Gateway HTTP API | Proxies /recolor to EC2 server |
| S3 Bucket 1 | Stores hand images (`nailcolorizer-hand-inputs`) |
| S3 Bucket 2 | Stores preset overlay images (`nailcolorizer-preset-overlays`) |
| IAM Roles | Allow EC2 to read/write to S3 |

---

## 🚀 Deployment

1. Extract this ZIP.
2. Open terminal in the `terraform/` folder.
3. Initialize Terraform:
```bash
terraform init
```

4. Apply infrastructure (replace with your EC2 key pair name):
```bash
terraform apply -var="key_pair_name=your-key-name"
```

5. Upload hand images to `nailcolorizer-hand-inputs` via AWS Console or CLI.

---

## 🧪 API Test with cURL

Once deployed, test the API with:

```bash
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/recolor \
  -F "file=@hand.jpg" \
  -F "color=#FF69B4"
```

> Replace `<api-id>` and `<region>` with values from the API Gateway endpoint.

---

## 🛠️ Useful Tips

- Logs: View EC2 logs using `tmux attach -t nailcolorizer` after SSH.
- Security Groups: Port 8000 is open for API Gateway; restrict in production.
- HTTPS: Add NGINX + SSL for production environments.

---

## ✨ Notes

- This solution uses rembg's ONNX backend (no torch needed).
- Make sure images are in `.png` or `.jpg` format.

