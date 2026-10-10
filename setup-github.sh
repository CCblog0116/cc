#!/usr/bin/env bash
# One-time GitHub setup for sec-english-blog
# Usage: bash setup-github.sh <your-github-username>
set -e
USER="$1"
REPO="sec-english-blog"
if [ -z "$USER" ]; then
  echo "Usage: bash setup-github.sh <your-github-username>"
  exit 1
fi
cd "$(dirname "$0")"

# 1. Update baseUrl in quartz.config.yaml
sed -i "s|GITHUB_USERNAME.github.io/sec-english-blog|${USER}.github.io/${REPO}|" quartz.config.yaml

# 2. Point origin to your repo (create it on github.com first: New repository -> ${REPO}, public, no README)
git remote set-url origin "https://github.com/${USER}/${REPO}.git"

# 3. Commit everything and push
git add -A
git commit -m "Initial commit: Quartz 5 minimalist sec-english blog" || true
git push -u origin v5

echo ""
echo "Done. Now go to: https://github.com/${USER}/${REPO}/settings/pages"
echo "Under 'Source', select 'GitHub Actions'. Site will be live at:"
echo "  https://${USER}.github.io/${REPO}/"
