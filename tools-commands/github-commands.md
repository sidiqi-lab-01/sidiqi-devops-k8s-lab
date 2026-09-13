# GitHub and Git Command Reference

## Repository Status

```bash
git status
Shows modified, staged, and untracked files.

git status --short

Provides a concise working-tree view.

Current Branch
git branch --show-current

Shows the branch currently checked out.

List Branches
git branch

Lists local branches.

git branch -a

Lists local and remote branches.

Create a Feature Branch
git checkout -b feature/example

Creates and switches to a new feature branch.

Switch Branches
git checkout main

Switches to the main branch.

Update Main
git pull --ff-only origin main

Updates local main without creating an unnecessary merge commit.

View Changes
git diff

Shows unstaged changes.

git diff --cached

Shows staged changes.

git diff --stat

Shows a summary of changed files.

git diff --check

Checks for whitespace errors.

Stage Files
git add filename

Stages a specific file.

git add .

Stages changes under the current directory.

Use selective staging when possible.

Commit Changes
git commit -m "feat: add new capability"

Creates a commit.

Common prefixes:

feat
fix
docs
refactor
test
chore
View Commit History
git log --oneline

Shows compact history.

git log -5 --oneline

Shows the last five commits.

Push Feature Branch
git push -u origin feature/example

Pushes the branch and configures upstream tracking.

View Remote
git remote -v

Displays configured Git remotes.

GitHub Authentication
gh auth status

Shows GitHub CLI authentication status.

List Issues
gh issue list

Lists open issues.

gh issue list --state all

Lists open and closed issues.

View Issue
gh issue view 76

Displays a specific issue.

Create Issue
gh issue create \
  --title "Add capability" \
  --body "Implementation requirements"

Creates a GitHub issue.

List Pull Requests
gh pr list

Lists open pull requests.

Create Pull Request
gh pr create \
  --base main \
  --head feature/example \
  --title "Add example capability" \
  --body "Closes #123"

Creates a pull request.

View Pull Request
gh pr view 130

Displays PR information.

View PR Files
gh pr diff 130 --name-only

Lists files changed by a PR.

Check PR Status
gh pr checks 130

Displays CI/CD checks.

Squash Merge
gh pr merge 130 --squash

Squash-merges the pull request.

The feature branch is retained unless --delete-branch is explicitly used.

GitHub API
gh api repos/OWNER/REPOSITORY

Queries GitHub through the REST API.

Practical Workflow
git checkout main
git pull --ff-only origin main
git checkout -b feature/example

# make changes

git diff
git add .
git diff --cached
git commit -m "feat: implement example"
git push -u origin feature/example

gh pr create \
  --base main \
  --head feature/example \
  --title "Implement example" \
  --body "Closes #123"

