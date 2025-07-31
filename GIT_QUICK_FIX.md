# Quick Git Fix for Divergent Branches

## 🚨 **Immediate Solution**

Choose one of these commands based on your preference:

### **Option 1: Merge Strategy (Recommended)**
```bash
git config pull.rebase false
git pull
```

### **Option 2: Rebase Strategy (Clean history)**
```bash
git config pull.rebase true
git pull
```

### **Option 3: Fast-forward only (Safest)**
```bash
git config pull.ff only
git pull
```

## 🔧 **What Each Option Does:**

### **Merge (Default)**
- ✅ **Safe and simple**
- ✅ **Preserves both histories**
- ✅ **Creates a merge commit**
- ❌ **History can look messy**

### **Rebase**
- ✅ **Clean, linear history**
- ✅ **No merge commits**
- ❌ **Can be complex with conflicts**
- ❌ **Rewrites commit history**

### **Fast-forward only**
- ✅ **Safest option**
- ✅ **Only pulls if no conflicts**
- ❌ **Fails if branches diverged**

## 🚀 **Automated Solution**

Use the git-sync script I created:

```bash
chmod +x git-sync.sh
./git-sync.sh
```

This script will:
1. ✅ **Auto-commit** any uncommitted changes
2. ✅ **Configure** git pull strategy
3. ✅ **Fetch** latest changes
4. ✅ **Merge** with remote branch
5. ✅ **Push** your changes
6. ✅ **Handle conflicts** gracefully

## 📋 **Step-by-Step Manual Process**

If you prefer to do it manually:

### 1. **Save your work**
```bash
git add .
git commit -m "Save current work"
```

### 2. **Configure pull strategy**
```bash
git config pull.rebase false  # Use merge strategy
```

### 3. **Pull changes**
```bash
git pull origin main  # or your branch name
```

### 4. **Resolve conflicts (if any)**
```bash
# Edit conflicted files
git add .
git commit -m "Resolve merge conflicts"
```

### 5. **Push your changes**
```bash
git push origin main  # or your branch name
```

## 🔍 **Understanding the Issue**

This happens when:
- ✅ **You made local commits**
- ✅ **Someone else pushed to the same branch**
- ✅ **Git doesn't know how to combine them**

## 💡 **Prevention Tips**

### **Always pull before pushing:**
```bash
git pull
git push
```

### **Use feature branches:**
```bash
git checkout -b feature/my-feature
# Make changes
git push origin feature/my-feature
```

### **Set global preference:**
```bash
git config --global pull.rebase false  # Set globally
```

## 🆘 **If Things Go Wrong**

### **Abort a merge:**
```bash
git merge --abort
```

### **Abort a rebase:**
```bash
git rebase --abort
```

### **Reset to last known good state:**
```bash
git reset --hard HEAD~1  # Go back one commit
```

### **See what happened:**
```bash
git log --oneline -10    # See recent commits
git status               # See current state
```

## 🎯 **Recommended Quick Fix**

For your immediate issue, just run:

```bash
git config pull.rebase false
git pull
git push
```

This will use the merge strategy (safest) and resolve your divergent branches issue.