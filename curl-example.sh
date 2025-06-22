#!/bin/bash
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/recolor \
  -F "file=@hand.jpg" \
  -F "color=#FF69B4"
