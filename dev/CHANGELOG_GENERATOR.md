# Changelog draft generator

`bin/generate_changelog` compares two taxonomy checkouts and creates a deterministic Markdown draft for the taxonomy section of a release changelog.

The generator derives:

- counts of new categories and base attributes;
- summaries of the largest new category areas in each vertical;
- representative new category and attribute names;
- attribute assignments added to existing categories; and
- added or refreshed localization locales.

## Usage

Create worktrees for the revisions to compare, then run the generator from `dev/`:

```sh
git worktree add /tmp/taxonomy-base <base-ref>
git worktree add /tmp/taxonomy-head <head-ref>

cd dev
bin/generate_changelog \
  --base /tmp/taxonomy-base \
  --head /tmp/taxonomy-head \
  --output /tmp/changelog-draft.md
```

Without `--output`, the draft is written to standard output.

## Manual notes

Some public changes cannot be inferred safely from taxonomy data. Pass a reviewed YAML file with release-specific vertical notes or additional sections:

```yaml
vertical_notes:
  fb:
    - Renames the `fb` vertical from `Food, Beverages & Tobacco` to `Food & Beverages`.
additional_sections:
  "📦 Distribution":
    - Distribution files are now published as release assets.
```

```sh
bin/generate_changelog \
  --base /tmp/taxonomy-base \
  --head /tmp/taxonomy-head \
  --notes /tmp/changelog-notes.yml \
  --output /tmp/changelog-draft.md
```

Manual notes are deliberately external to the generator so release-specific statements cannot accidentally carry into a future release.

## Editorial review

The output is a draft, not a publishable changelog without review. Compare it with the complete base-to-head diff and the PR description. In particular, check for:

- category or vertical renames, relocations, removals, and hierarchy changes;
- attribute- or value-only changes not represented by category additions;
- compatibility exceptions and changes in inheritance behavior;
- localization changes;
- distribution and release-process changes; and
- integration or mapping changes.

Keep only details useful to public changelog readers. Remove internal review gates, validation details, and implementation notes. Verify every count, example, and manual note against the final PR head before publishing.
