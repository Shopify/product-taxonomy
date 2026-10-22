---
name: taxonomy-release
description: Prepare, review, or publish a taxonomy release in this repository. Use when opening or reviewing a release data PR, writing the changelog or GitHub release notes, or cutting a release with bin/product_taxonomy release.
---

# Taxonomy release

Follow these steps for every release so each one is prepared and checked the
same way. Run commands from `dev/` unless noted.

## 1. Scope

- Start from the latest `main`. The last release is the latest GitHub release
  (`gh release view --json tagName --jq .tagName`).
- Change only taxonomy data, localizations, mappings and the changelog. Do not
  edit `data/integrations/README.md` or other docs unless the release changes
  what they describe.
- Keep published content unless its removal is intended and disclosed: IDs,
  values, the order of custom-sorted values, category assignments and
  translations of records that still exist.
- Disclose every rename and removal of a published category, attribute or value
  in the changelog.

## 2. Attribute quality

Check every new attribute before the data PR is ready:

| Rule | Example |
|---|---|
| Every base attribute except Color has an Other value, `<friendly_id>__other`, listed last | `Assembly required`: `No`, `Yes`, `Other` |
| An attribute about color is an extended attribute of Color (`values_from: color`), not a new base attribute | `D ring color` |
| Every `X color` extension has an `X pattern` extension (`values_from: pattern`) on the same categories | `D ring pattern` |
| Names use sentence case and do not repeat the category name | `Garment length type`, not `Capes Garment length type` |
| Attributes are not gendered or tied to one brand or model | Not `Her size` or `Compatible Samsung The Frame TV model year` |

## 3. Return reasons

- Existing categories keep their return reasons exactly as on `main`.
- New categories use `return_reasons: inherit` unless the release intends
  otherwise.
- Verify with the generated `dist/en/categories.json`, not by reading
  `inherit` chains in YAML by hand: compare each existing category's return
  reasons between the last release tag and the release branch.

## 4. Mappings

- Keep all existing mapping rules and exclusions unchanged.
- Map new categories with the existing policy (the nearest mapped ancestor),
  keeping existing exclusions for their descendants.

## 5. Localizations

- Every locale covers every English name and description.
- Records that still exist keep their translations. Remove translations only
  for records the release retires.
- Describe in the PR which translations are new, changed or not yet reviewed
  by language owners.

## 6. Generate and test

```sh
bin/product_taxonomy dist --locales all
bundle exec rake test
bundle exec rake schema:vet
```

## 7. Changelog

1. Generate a draft from the last release tag and the release branch:

   ```sh
   git worktree add /tmp/taxonomy-base <last-release-tag>
   git worktree add /tmp/taxonomy-head <release-branch>
   bin/generate_changelog --base /tmp/taxonomy-base --head /tmp/taxonomy-head \
     --notes /tmp/changelog-notes.yml --output /tmp/changelog-draft.md
   ```

   See `dev/CHANGELOG_GENERATOR.md` for the notes file.
2. List every PR merged since the last tag and add notes for changes the draft
   cannot infer, such as disclosures, return reasons and removals:

   ```sh
   git log --first-parent --oneline <last-release-tag>..origin/main
   ```

3. Put the result in the `Unreleased` section of `CHANGELOG.md`.

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
