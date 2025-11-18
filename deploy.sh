#!/bin/bash

# KatelyaTV Server Deployment Script
# For shared hosting environment with limited disk space

set -e

echo "🚀 Starting KatelyaTV deployment..."

# Configuration
DEPLOY_DIR="public_html"
BACKUP_DIR="public_html_backup"
TEMP_DIR="temp_deploy"
MAX_SIZE_MB=100

# Function to check disk usage
check_disk_usage() {
    local dir=$1
    local size_mb=$(du -sm "$dir" 2>/dev/null | cut -f1)
    echo $size_mb
}

# Function to cleanup old files
cleanup_old_deployment() {
    echo "🧹 Cleaning up old deployment..."
    
    # Remove old backup if exists
    if [ -d "$BACKUP_DIR" ]; then
        rm -rf "$BACKUP_DIR"
        echo "   Removed old backup"
    fi
    
    # Backup current deployment
    if [ -d "$DEPLOY_DIR" ] && [ "$(ls -A $DEPLOY_DIR 2>/dev/null)" ]; then
        cp -r "$DEPLOY_DIR" "$BACKUP_DIR"
        echo "   Created backup of current deployment"
    fi
}

# Function to extract and prepare deployment
prepare_deployment() {
    echo "📦 Preparing deployment files..."
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Extract deployment archive
    if [ -f "katelyatv-deploy.tar.gz" ]; then
        tar -xzf "katelyatv-deploy.tar.gz" -C "$TEMP_DIR"
        echo "   Extracted deployment archive"
    else
        echo "❌ Deployment archive not found!"
        exit 1
    fi
    
    # Check deployment size
    local deploy_size=$(check_disk_usage "$TEMP_DIR")
    echo "   Deployment size: ${deploy_size}MB"
    
    if [ $deploy_size -gt $MAX_SIZE_MB ]; then
        echo "⚠️  Warning: Deployment size (${deploy_size}MB) is large for shared hosting"
        echo "   Consider optimizing assets or removing unnecessary files"
    fi
}

# Function to deploy files
deploy_files() {
    echo "🔄 Deploying files..."
    
    # Clear deployment directory
    if [ -d "$DEPLOY_DIR" ]; then
        rm -rf "${DEPLOY_DIR:?}"/*
    else
        mkdir -p "$DEPLOY_DIR"
    fi
    
    # Copy new files
    cp -r "$TEMP_DIR"/* "$DEPLOY_DIR"/
    echo "   Files copied to deployment directory"
    
    # Set proper permissions
    chmod -R 755 "$DEPLOY_DIR"
    find "$DEPLOY_DIR" -type f -exec chmod 644 {} \;
    echo "   Permissions set"
}

# Function to verify deployment
verify_deployment() {
    echo "✅ Verifying deployment..."
    
    # Check if index.html exists
    if [ -f "$DEPLOY_DIR/index.html" ]; then
        echo "   ✓ Main application file found"
    else
        echo "   ❌ Main application file missing!"
        return 1
    fi
    
    # Check if .htaccess exists
    if [ -f "$DEPLOY_DIR/.htaccess" ]; then
        echo "   ✓ Server configuration found"
    else
        echo "   ⚠️  Server configuration missing"
    fi
    
    # Check deployment size
    local final_size=$(check_disk_usage "$DEPLOY_DIR")
    echo "   Final deployment size: ${final_size}MB"
    
    return 0
}

# Function to cleanup temporary files
cleanup_temp() {
    echo "🧹 Cleaning up temporary files..."
    
    # Remove temporary directory
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        echo "   Temporary files removed"
    fi
    
    # Remove deployment archive
    if [ -f "katelyatv-deploy.tar.gz" ]; then
        rm -f "katelyatv-deploy.tar.gz"
        echo "   Deployment archive removed"
    fi
}

# Function to rollback on failure
rollback_deployment() {
    echo "🔄 Rolling back deployment..."
    
    if [ -d "$BACKUP_DIR" ]; then
        rm -rf "${DEPLOY_DIR:?}"/*
        cp -r "$BACKUP_DIR"/* "$DEPLOY_DIR"/
        echo "   Rollback completed"
    else
        echo "   No backup available for rollback"
    fi
}

# Main deployment process
main() {
    echo "🎬 KatelyaTV Deployment Script"
    echo "================================"
    
    # Check if we're in the right directory
    if [ ! -f "katelyatv-deploy.tar.gz" ]; then
        echo "❌ Deployment archive not found in current directory"
        echo "   Please upload katelyatv-deploy.tar.gz first"
        exit 1
    fi
    
    # Start deployment
    cleanup_old_deployment
    prepare_deployment
    
    # Deploy with error handling
    if deploy_files && verify_deployment; then
        cleanup_temp
        echo ""
        echo "🎉 Deployment completed successfully!"
        echo "   Site URL: https://wwwwwww.sylu.net"
        echo "   Deployment size: $(check_disk_usage "$DEPLOY_DIR")MB"
        echo ""
        echo "📝 Next steps:"
        echo "   1. Test the application in your browser"
        echo "   2. Configure video sources if needed"
        echo "   3. Set up your password for access"
    else
        echo ""
        echo "❌ Deployment failed!"
        rollback_deployment
        cleanup_temp
        exit 1
    fi
}

# Run main function
main "$@"
