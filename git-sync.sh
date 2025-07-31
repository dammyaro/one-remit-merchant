#!/bin/bash

# Git sync helper script
# Resolves divergent branches and syncs with remote

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔄 Git Sync Helper${NC}"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Show current status
echo -e "${BLUE}📊 Current Git Status:${NC}"
git status --short

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    echo -e "${BLUE}💾 Committing changes...${NC}"
    
    # Add all changes
    git add .
    
    # Commit with timestamp
    COMMIT_MSG="Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MSG"
    
    echo -e "${GREEN}✅ Changes committed: $COMMIT_MSG${NC}"
fi

# Configure git pull strategy (merge by default)
echo -e "${BLUE}⚙️  Configuring Git pull strategy...${NC}"
git config pull.rebase false

# Fetch latest changes
echo -e "${BLUE}📥 Fetching latest changes...${NC}"
git fetch origin

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${BLUE}🌿 Current branch: $CURRENT_BRANCH${NC}"

# Check if remote branch exists
if git ls-remote --exit-code --heads origin "$CURRENT_BRANCH" > /dev/null 2>&1; then
    echo -e "${BLUE}🔄 Syncing with remote branch...${NC}"
    
    # Pull with merge strategy
    if git pull origin "$CURRENT_BRANCH"; then
        echo -e "${GREEN}✅ Successfully synced with remote${NC}"
    else
        echo -e "${YELLOW}⚠️  Merge conflicts detected${NC}"
        echo -e "${BLUE}🔧 Resolving conflicts...${NC}"
        
        # Show conflicted files
        echo -e "${YELLOW}Conflicted files:${NC}"
        git diff --name-only --diff-filter=U
        
        echo -e "${BLUE}💡 Manual resolution needed:${NC}"
        echo -e "   1. Edit conflicted files to resolve conflicts"
        echo -e "   2. Run: ${YELLOW}git add .${NC}"
        echo -e "   3. Run: ${YELLOW}git commit -m 'Resolve merge conflicts'${NC}"
        echo -e "   4. Run: ${YELLOW}git push origin $CURRENT_BRANCH${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  Remote branch doesn't exist. Creating...${NC}"
fi

# Push changes
echo -e "${BLUE}📤 Pushing to remote...${NC}"
if git push origin "$CURRENT_BRANCH"; then
    echo -e "${GREEN}✅ Successfully pushed to remote${NC}"
else
    echo -e "${RED}❌ Failed to push to remote${NC}"
    exit 1
fi

# Final status
echo -e "${BLUE}📊 Final Status:${NC}"
git log --oneline -5

echo -e "${GREEN}🎉 Git sync completed successfully!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "   🌿 Branch: $CURRENT_BRANCH"
echo -e "   📝 Latest commit: $(git log -1 --pretty=format:'%h - %s')"
echo -e "   🔄 Status: Synced with remote"