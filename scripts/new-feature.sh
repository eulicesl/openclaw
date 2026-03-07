#!/usr/bin/env bash
# new-feature.sh — Start a new feature branch from a fresh upstream sync
# Usage: ./scripts/new-feature.sh ios-voice-improvements
#        ./scripts/new-feature.sh fix/ios-reconnect-bug

set -e

BRANCH_NAME="$1"

if [ -z "$BRANCH_NAME" ]; then
  echo "Usage: $0 <branch-name>"
  echo "Examples:"
  echo "  $0 ios-voice-improvements"
  echo "  $0 fix/ios-reconnect-bug"
  echo "  $0 chore/ios-bump-deps"
  exit 1
fi

# Prefix with feature/ if no type prefix provided
if [[ "$BRANCH_NAME" != feature/* && "$BRANCH_NAME" != fix/* && "$BRANCH_NAME" != chore/* ]]; then
  BRANCH_NAME="feature/$BRANCH_NAME"
fi

echo "🔄 Syncing main with upstream before branching..."
git checkout main
git fetch upstream
git merge upstream/main --ff-only
git push origin main

echo "🌿 Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

echo ""
echo "✅ Ready! You're on: $(git branch --show-current)"
echo ""
echo "When you're done:"
echo "  git push origin $BRANCH_NAME"
echo "  gh pr create --repo eulicesl/openclaw --title 'feat: ...' --body '...'"
echo ""
echo "To open a PR upstream when ready:"
echo "  gh pr create --repo openclaw/openclaw --head eulicesl:$BRANCH_NAME --title '...' --body '...'"
