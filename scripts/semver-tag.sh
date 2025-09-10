set -euo pipefail

# Always have tags locally
git fetch --tags --force >/dev/null 2>&1 || true

last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
commit_msg=$(git log -1 --pretty=%B)

bump="none"
shopt -s nocasematch
if [[ "$commit_msg" =~ BREAKING[[:space:]]CHANGE ]] || [[ "$commit_msg" =~ ^[a-z]+(\([^)]+\))?!: ]]; then
  bump="major"
elif [[ "$commit_msg" =~ ^feat(\([^)]+\))?: ]]; then
  bump="minor"
elif [[ "$commit_msg" =~ ^(fix|perf)(\([^)]+\))?: ]]; then
  bump="patch"
else
  echo "No release tag for commit message: $commit_msg"
  exit 0
fi
shopt -u nocasematch

ver=${last_tag#v}
IFS='.' read -r major minor patch <<<"${ver:-0.0.0}"

case "$bump" in
  major) major=$((major+1)); minor=0; patch=0 ;;
  minor) minor=$((minor+1)); patch=0 ;;
  patch) patch=$((patch+1)) ;;
esac

new_tag="v${major}.${minor}.${patch}"

if git rev-parse -q --verify "refs/tags/$new_tag" >/dev/null; then
  echo "Tag $new_tag already exists. Skipping."
  exit 0
fi

git tag -a "$new_tag" -m "ci: release $new_tag"
# push right away (works locally & in CI with checkout token)
git push origin "$new_tag"

echo "Created tag $new_tag"
