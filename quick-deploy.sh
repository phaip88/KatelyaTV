#!/bin/bash

# Quick deployment script for manual upload
# Usage: ./quick-deploy.sh

echo "🚀 Quick Deploy KatelyaTV"
echo "========================="

# Check if deployment archive exists
if [ ! -f "katelyatv-deploy.tar.gz" ]; then
    echo "❌ katelyatv-deploy.tar.gz not found!"
    echo "   Download it from GitHub Actions artifacts first"
    exit 1
fi

# Extract to public_html
echo "📦 Extracting files..."
tar -xzf katelyatv-deploy.tar.gz -C public_html/

# Set permissions
echo "🔧 Setting permissions..."
chmod -R 755 public_html/
find public_html/ -type f -exec chmod 644 {} \;

# Cleanup
echo "🧹 Cleaning up..."
rm -f katelyatv-deploy.tar.gz

echo "✅ Deployment complete!"
echo "   Site: https://wwwwwww.sylu.net"
