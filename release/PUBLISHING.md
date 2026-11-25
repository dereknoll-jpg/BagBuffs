# Tagged releases

CurseForge project: 1825109. GitHub has an active push webhook to CurseForge.
The webhook's successful HTTP response confirms delivery, not completed packaging or approval.
The owner confirmed that Package All Commits is enabled. Branch pushes should
therefore trigger packaging too; a missing tag does not explain a missing file.
Inspect the CurseForge packaging log for the job's actual result.
Untagged commits may be classified as Alpha; check that filter in the file list.
Use the established version format 1.0.0-rc.N, not 1.0.N or padded variants.

For every release:

1. Update Version in both addon TOCs, P.version in Core.lua, current release notes,
   the cumulative changelog and current upload-kit paths.
2. Run scripts/Package-Release.ps1 and review the resulting ZIP.
3. Commit and push main. Create an annotated version tag (for example 1.0.0-rc.5)
   using SatchelSense/RELEASE-NOTES.md as the annotation, then push that exact tag.
4. Publish a GitHub release for the same tag using those notes and attach only
   dist/SatchelSense-VERSION.zip as the addon asset. Do not attach the larger media kit
   as an installable addon.
   GitHub release assets must be named SatchelSense-1.0.0-rc.N.zip. Mark release
   candidates as prereleases on GitHub. The earlier 1.0.4 release was a naming
   detour and is superseded by 1.0.0-rc.5; do not reuse that numbering.
5. Verify GitHub's tag-push webhook delivery and CurseForge's packaging/file status.
   If packaging fails, inspect the error before retrying. Do not move an existing
   public version tag to another commit.

.pkgmeta stages both required addon folders at the archive root, excludes development
files, and tells CurseForge to use the current written release notes instead of a
raw commit log. The PocketBuffs folder is the required legacy settings loader.

Do not put webhook URLs or API tokens in files, notes, or console output.
