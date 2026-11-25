# Tagged releases

CurseForge project: 1825109. GitHub has an active push webhook to CurseForge.
The webhook's successful HTTP response confirms delivery, not completed packaging or approval.
The default CurseForge packager builds tagged commits; a normal branch push alone
does not create a release unless packaging every commit is explicitly enabled.

For every release:

1. Update Version in both addon TOCs, P.version in Core.lua, current release notes,
   the cumulative changelog and current upload-kit paths.
2. Run scripts/Package-Release.ps1 and review the resulting ZIP.
3. Commit and push main. Create an annotated version tag (for example 1.0.4)
   using SatchelSense/RELEASE-NOTES.md as the annotation, then push that exact tag.
4. Publish a GitHub release for the same tag using those notes and attach only
   dist/SatchelSense-VERSION.zip as the addon asset. Do not attach the larger media kit
   as an installable addon.
5. Verify GitHub's tag-push webhook delivery and CurseForge's packaging/file status.
   If packaging fails, inspect the error before retrying. Do not move an existing
   public version tag to another commit.

.pkgmeta stages both required addon folders at the archive root, excludes development
files, and tells CurseForge to use the current written release notes instead of a
raw commit log. The PocketBuffs folder is the required legacy settings loader.

Do not put webhook URLs or API tokens in files, notes, or console output.
