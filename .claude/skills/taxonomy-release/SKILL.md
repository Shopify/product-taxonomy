---
name: taxonomy-release
description: Prepare, review, or publish a taxonomy release in this repository. Use when opening or reviewing a release data PR, writing the changelog or GitHub release notes, or cutting a release with bin/product_taxonomy release.
---

# Taxonomy release

Follow these steps for every release so each one is prepared and checked the
same way. Run commands from `dev/` unless noted.

## 1. Scope

- Start from the latest `main`. Find the last GitHub release with
  `gh release view --json tagName --jq .tagName`, then check for later patch
  tags on the remote with `git ls-remote --tags origin`. Use the latest
  applicable published tag as the changelog base, including patches; a local
  tag of the same name may point to a different commit.
- Change only taxonomy data, localizations, mappings and the changelog. Do not
  edit `data/integrations/README.md` or other docs unless the release changes
  what they describe.
- Never renumber, reuse or reassign a category, attribute or value ID, including
  IDs from retired records.
- Keep published content unless its removal is intended and disclosed: values,
  the order of custom-sorted values, category assignments and translations of
  records that still exist. When removing an attribute, remove its category
  references, values that are no longer referenced by any attribute, and its
  attribute/value localizations. Preserve unrelated records and their order.
- Disclose every rename and removal of a published category, attribute or value
  in the changelog.

## 2. Attribute quality

Check these invariants across the resulting taxonomy, not only new attributes.
Review every new or changed attribute and category assignment against them;
compare with the PR base to identify pre-existing exceptions and do not add new
violations:

| Rule | Example |
|---|---|
| Every base attribute except Color has an Other value, `<friendly_id>__other`, listed last | `Assembly required`: `No`, `Yes`, `Other` |
| An attribute for a part or component's color extends Color (`values_from: color`), rather than adding a new base attribute | `D ring color` |
| Every `X color` extension has an `X pattern` extension (`values_from: pattern`) on the same categories; new or changed assignments must include the pair | `D ring pattern` |
| Names use sentence case and do not repeat the category name | `Garment length type`, not `Capes Garment length type` |
| Avoid gendered attributes and unnecessarily granular brand/model-specific attributes when a general compatibility model is more appropriate | Not `Her size` or `Compatible Samsung The Frame TV model year` |

## 3. Return reasons

- Existing categories keep their return reasons exactly as on the release PR's
  base (the latest `main` after fetching). Compare the base with the release
  branch, not the last release tag; tag-to-head is a separate changelog check.
- New categories use `return_reasons: inherit` unless the release intends
  otherwise.
- Generate `dist/en/categories.json` separately from clean `origin/main` and
  the release branch (run `bin/product_taxonomy dist --locales en` from `dev/`
  in each checkout). Compare the ordered return-reason IDs for every category
  present on `main`; the JSON contains the effective inherited reasons. Do not
  compare committed `dist/` files, which can be stale or absent, or use only the
  last release tag as the baseline.

## 4. Mappings

- Keep all existing mapping rules and exclusions unchanged.
- Map new categories with the existing policy (the nearest mapped ancestor),
  keeping existing exclusions for their descendants.

## 5. Localizations

- Every locale covers every English name and description.
- Records that still exist keep their translations. Remove translations only
  for records the release retires or attribute/value records removed during
  cleanup. Preserve YAML scalar quoting where needed: Polish `'ON'` must
  continue to parse as a string rather than a boolean.
- Describe in the PR which translations are new, changed or not yet reviewed
  by language owners.

## 6. Generate and test

```sh
bin/product_taxonomy dist --locales all
bundle exec rake test
bundle exec rake test:orphan
bundle exec rake schema:vet
```

## 7. Changelog

1. Generate a draft from the last published tag (including later patch tags)
   and the release branch. Run from `dev/` on that branch:

   ```sh
   git fetch origin main
   last_published_tag=$(git ls-remote --tags --refs origin 'v*' |
     awk -F/ '{print $NF}' |
     grep -E '^v[0-9]{4}-[0-9]{2}(-patch(-[0-9]+)?)?$' |
     sort -r | head -n 1)
   git fetch --no-tags origin "refs/tags/$last_published_tag"
   base_commit=$(git rev-parse 'FETCH_HEAD^{commit}')
   worktree_root=$(mktemp -d)
   draft_path=$(mktemp)
   git worktree add --detach "$worktree_root/base" "$base_commit"
   git worktree add --detach "$worktree_root/head" HEAD
   bin/generate_changelog \
     --base "$worktree_root/base" \
     --head "$worktree_root/head" \
     --output "$draft_path"
   git worktree remove "$worktree_root/base"
   git worktree remove "$worktree_root/head"
   rmdir "$worktree_root"
   echo "Changelog draft: $draft_path"
   ```

   Confirm the selected tag against the published releases before running the
   comparison. Fetching the remote tag without changing local tags avoids a
   stale or moved local tag. See `dev/CHANGELOG_GENERATOR.md` for optional
   reviewed manual notes; create a release-specific YAML file before passing
   it with `--notes`.
2. List every PR merged since the last tag and add notes for changes the draft
   cannot infer, such as disclosures, return reasons and removals:

   ```sh
   git log --first-parent --oneline <last-published-tag>..origin/main
   ```

3. Put the draft in the `Unreleased` section of `CHANGELOG.md`. Before cutting
   the release, turn that section into `## <version>` and add a fresh
   `## Unreleased` heading for subsequent changes; the release command does not
   edit the changelog.

## 8. Release

1. Confirm the version with the taxonomy owners.
2. On a clean `main`, run
   `bin/product_taxonomy release <version> <next-version>-unstable`. It creates
   the `release-v<version>` branch, updates `VERSION`, mappings, `dist/`, the
   docs and the version badges, tags `v<version>`, then commits the next
   unstable version on the same branch. Follow the next steps it prints: push the
   branch, open and merge the PR, push the tag, create the GitHub release,
   publish the release assets and spot-check one.
3. Write the GitHub release body in the previous release's format: one intro
   line with the version and an explore link, then `## Changelog` with the
   sections that apply: 📚 Taxonomy Tree, ⚠️ Disclosures, 🔄 Return Reasons,
   🌐 Localization, 📦 Distribution.

## 9. Public text

PR descriptions, the changelog and release notes describe changes for
taxonomy users. Do not link private resources or describe work that is not
part of the release.
