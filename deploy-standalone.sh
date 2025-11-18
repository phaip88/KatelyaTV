#!/bin/bash

# KatelyaTV Standalone Server Deployment Script
# For shared hosting environment with Node.js support

set -e

echo "🚀 Starting KatelyaTV standalone deployment..."

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
    echo "🔄 Deploying standalone application..."
    
    # Clear deployment directory
    if [ -d "$DEPLOY_DIR" ]; then
        rm -rf "${DEPLOY_DIR:?}"/*
    else
        mkdir -p "$DEPLOY_DIR"
    fi
    
    # Copy standalone server files
    cp -r "$TEMP_DIR"/* "$DEPLOY_DIR"/
    
    # Create startup script
    cat > "$DEPLOY_DIR/start.sh" << 'EOF'
#!/bin/bash
export NODE_ENV=production
export PORT=3000
export HOSTNAME=0.0.0.0
node server.js
EOF
    
    chmod +x "$DEPLOY_DIR/start.sh"
    
    # Set proper permissions
    chmod -R 755 "$DEPLOY_DIR"
    find "$DEPLOY_DIR" -type f -name "*.js" -exec chmod 644 {} \;
    find "$DEPLOY_DIR" -type f -name "*.json" -exec chmod 644 {} \;
    
    echo "   Files deployed and permissions set"
}

# Function to verify deployment
verify_deployment() {
    echo "✅ Verifying deployment..."
    
    # Check if server.js exists
    if [ -f "$DEPLOY_DIR/server.js" ]; then
        echo "   ✓ Server application found"
    else
        echo "   ❌ Server application missing!"
        return 1
    fi
    
    # Check if package.json exists
    if [ -f "$DEPLOY_DIR/package.json" ]; then
        echo "   ✓ Package configuration found"
    else
        echo "   ⚠️  Package configuration missing"
    fi
    
    # Check deployment size
    local final_size=$(check_disk_usage "$DEPLOY_DIR")
    echo "   Final deployment size: ${final_size}MB"
    
    return 0
}

# Function to start application
start_application() {
    echo "🚀 Starting KatelyaTV application..."
    
    cd "$DEPLOY_DIR"
    
    # Check if Node.js is available
    if command -v node >/dev/null 2>&1; then
        echo "   Node.js version: $(node --version)"
        
        # Start the application in background
        nohup ./start.sh > app.log 2>&1 &
        APP_PID=$!
        
        echo "   Application started with PID: $APP_PID"
        echo "   Log file: $DEPLOY_DIR/app.log"
        
        # Wait a moment and check if it's still running
        sleep 3
        if kill -0 $APP_PID 2>/dev/null; then
            echo "   ✅ Application is running successfully"
            echo "   Access URL: https://wwwwwww.sylu.net"
        else
            echo "   ❌ Application failed to start"
            echo "   Check log: tail -f $DEPLOY_DIR/app.log"
            return 1
        fi
    else
        echo "   ❌ Node.js not found!"
        echo "   Please install Node.js or use static deployment"
        return 1
    fi
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
    echo "🎬 KatelyaTV Standalone Deployment Script"
    echo "========================================"
    
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
        if start_application; then
            cleanup_temp
            echo ""
            echo "🎉 Deployment completed successfully!"
            echo "   Site URL: https://wwwwwww.sylu.net"
            echo "   Deployment size: $(check_disk_usage "$DEPLOY_DIR")MB"
            echo "   Application log: $DEPLOY_DIR/app.log"
            echo ""
            echo "📝 Management commands:"
            echo "   Check status: ps aux | grep node"
            echo "   View logs: tail -f $DEPLOY_DIR/app.log"
            echo "   Stop app: pkill -f server.js"
            echo "   Restart: cd $DEPLOY_DIR && ./start.sh"
        else
            echo ""
            echo "⚠️  Deployment completed but application failed to start"
            echo "   Files are deployed, check Node.js configuration"
            cleanup_temp
        fi
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
