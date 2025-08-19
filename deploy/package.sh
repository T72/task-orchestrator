#!/bin/bash
# Package Task Orchestrator for distribution
# Creates a standalone package that can be deployed anywhere

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PACKAGE_NAME="task-orchestrator-deploy"
VERSION="1.0.0"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_FILE="${PACKAGE_NAME}-${VERSION}-${TIMESTAMP}.tar.gz"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Creating deployment package...${NC}"

# Create temporary packaging directory
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="${TEMP_DIR}/${PACKAGE_NAME}"
mkdir -p "${PACKAGE_DIR}"

echo "Packaging from: ${SOURCE_DIR}"
echo "Package directory: ${PACKAGE_DIR}"

# Copy essential files
echo "Copying core files..."
cp "${SOURCE_DIR}/tm" "${PACKAGE_DIR}/"
chmod +x "${PACKAGE_DIR}/tm"

# Copy enhanced version if it exists
if [ -f "${SOURCE_DIR}/tm_enhanced.py" ]; then
    echo "Copying enhanced version with collaboration..."
    cp "${SOURCE_DIR}/tm_enhanced.py" "${PACKAGE_DIR}/"
    chmod +x "${PACKAGE_DIR}/tm_enhanced.py"
fi

# Copy source modules if they exist
if [ -d "${SOURCE_DIR}/src" ]; then
    echo "Copying Python modules..."
    cp -r "${SOURCE_DIR}/src" "${PACKAGE_DIR}/"
fi

# Copy scripts
if [ -d "${SOURCE_DIR}/scripts" ]; then
    echo "Copying helper scripts..."
    mkdir -p "${PACKAGE_DIR}/scripts"
    for script in agent_helper.sh cleanup-hook.sh; do
        if [ -f "${SOURCE_DIR}/scripts/${script}" ]; then
            cp "${SOURCE_DIR}/scripts/${script}" "${PACKAGE_DIR}/scripts/"
            chmod +x "${PACKAGE_DIR}/scripts/${script}"
        fi
    done
fi

# Copy deployment tools
echo "Copying deployment tools..."
mkdir -p "${PACKAGE_DIR}/deploy"
cp "${SCRIPT_DIR}/install.sh" "${PACKAGE_DIR}/deploy/"
cp "${SCRIPT_DIR}/deploy.py" "${PACKAGE_DIR}/deploy/"
cp "${SCRIPT_DIR}/README.md" "${PACKAGE_DIR}/deploy/"
cp "${SCRIPT_DIR}/projects.txt.example" "${PACKAGE_DIR}/deploy/"
chmod +x "${PACKAGE_DIR}/deploy/install.sh"
chmod +x "${PACKAGE_DIR}/deploy/deploy.py"

# Copy orchestrator documentation
echo "Copying orchestrator guide..."
mkdir -p "${PACKAGE_DIR}/docs"
if [ -f "${SOURCE_DIR}/docs/guides/ORCHESTRATOR-GUIDE.md" ]; then
    cp "${SOURCE_DIR}/docs/guides/ORCHESTRATOR-GUIDE.md" "${PACKAGE_DIR}/docs/"
    echo "  Added orchestrator guide"
fi
if [ -f "${SOURCE_DIR}/docs/guides/QUICKSTART-CLAUDE-CODE.md" ]; then
    cp "${SOURCE_DIR}/docs/guides/QUICKSTART-CLAUDE-CODE.md" "${PACKAGE_DIR}/docs/"
    echo "  Added Claude Code quickstart"
fi

# Create minimal documentation
echo "Creating package documentation..."
cat > "${PACKAGE_DIR}/README.md" << EOF
# Task Orchestrator - Deployment Package
Version: ${VERSION}
Packaged: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Quick Start

1. Extract this package to your tools directory
2. Deploy to a project:
   \`\`\`bash
   ./deploy/install.sh /path/to/your/project
   \`\`\`

## Contents

- \`tm\` - Main task orchestrator executable
- \`src/\` - Python modules (if applicable)
- \`scripts/\` - Helper scripts
- \`deploy/\` - Deployment tools and documentation

## Deployment Options

### Single Project
\`\`\`bash
./deploy/install.sh /path/to/project
\`\`\`

### Multiple Projects
\`\`\`bash
python3 deploy/deploy.py --batch projects.txt
\`\`\`

See \`deploy/README.md\` for full deployment documentation.

## Requirements

- Python 3.8+
- Git (optional, but recommended)
- Unix-like environment (Linux, macOS) or Windows with WSL

## Support

For documentation and support, visit:
https://github.com/your-org/task-orchestrator
EOF

# Create version file
echo "${VERSION}" > "${PACKAGE_DIR}/VERSION"

# Create manifest
echo "Creating manifest..."
cat > "${PACKAGE_DIR}/MANIFEST.txt" << EOF
Task Orchestrator Deployment Package
Version: ${VERSION}
Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Platform: $(uname -s)

Files included:
$(cd "${PACKAGE_DIR}" && find . -type f | sort)

Checksums:
$(cd "${PACKAGE_DIR}" && find . -type f -exec sha256sum {} \; 2>/dev/null || find . -type f -exec shasum -a 256 {} \;)
EOF

# Create the archive
echo "Creating archive..."
cd "${TEMP_DIR}"
tar -czf "${SCRIPT_DIR}/${PACKAGE_FILE}" "${PACKAGE_NAME}"

# Calculate package size
PACKAGE_SIZE=$(du -h "${SCRIPT_DIR}/${PACKAGE_FILE}" | cut -f1)

# Cleanup
rm -rf "${TEMP_DIR}"

# Summary
echo ""
echo -e "${GREEN}✅ Package created successfully!${NC}"
echo ""
echo "Package: ${SCRIPT_DIR}/${PACKAGE_FILE}"
echo "Size: ${PACKAGE_SIZE}"
echo "Version: ${VERSION}"
echo ""
echo "To deploy this package:"
echo "1. Extract: tar -xzf ${PACKAGE_FILE}"
echo "2. Deploy: cd ${PACKAGE_NAME} && ./deploy/install.sh /your/project"
echo ""

# Optional: Create a latest symlink
ln -sf "${PACKAGE_FILE}" "${SCRIPT_DIR}/${PACKAGE_NAME}-latest.tar.gz"
echo "Latest symlink created: ${PACKAGE_NAME}-latest.tar.gz"