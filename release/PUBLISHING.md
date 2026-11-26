# Tagged releases

CurseForge project: 1825109. GitHub has an active push webhook to CurseForge.
The webhook's successful HTTP response confirms delivery, not completed packaging or approval.
The owner confirmed that Package All Commits is enabled. Branch pushes should
therefore trigger packaging too; a missing tag does not explain a missing file.
Inspect the CurseForge packaging log for the job's actual result.
Untagged commits may be classified as Alpha; check that filter in the file list.
Use the established version format 1.0.0-rc.N, not 1.0.N or padded variants.

For every release:

1. Update Version in all three addon TOCs, P.version in Core.lua, current release notes,
   the cumulative changelog and current upload-kit paths.
2. Run scripts/Package-Release.ps1 and review the resulting ZIP.
3. Commit and push main. Create an annotated version tag (for example 1.0.0-rc.6)
   using BagBuffs/RELEASE-NOTES.md as the annotation, then push that exact tag.
4. Publish a GitHub release for the same tag using those notes and attach only
   dist/BagBuffs-VERSION.zip as the addon asset. Do not attach the larger media kit
   as an installable addon.
   GitHub release assets must be named BagBuffs-1.0.0-rc.N.zip. Mark release
   candidates as prereleases on GitHub. The earlier 1.0.4 release was a naming
   detour and is superseded by 1.0.0-rc.6; do not reuse that numbering.
5. Verify GitHub's tag-push webhook delivery and CurseForge's packaging/file status.
   If packaging fails, inspect the error before retrying. Do not move an existing
   public version tag to another commit.

.pkgmeta stages all three required addon folders at the archive root, excludes development
files, and tells CurseForge to use the current written release notes instead of a
raw commit log. The SatchelSense and PocketBuffs folders are the required legacy settings loaders.

Do not put webhook URLs or API tokens in files, notes, or console output.

## BagBuffs naming and duplicate prevention

The existing CurseForge project remains 1825109 so downloads, comments and update continuity stay together. Update its display name/description/gallery with this kit; the older project slug may remain as a working link. The GitHub repository is now dereknoll-jpg/BagBuffs, with history and hooks retained. If CurseForge still shows the old source URL, update it to the new canonical GitHub URL.

Use only the existing automatic packaging path. It did produce the rc.5 release; the earlier manual fallback created a duplicate Beta. Do not manually upload another copy just because a webhook returns before the packaging job completes. Confirm the actual packaging/file status.
