# Purpose

GitSync.ps1 is a PowerShell script that allows a Git user to manage many interconnected repositories as a single repository by executing common git commands across each relevant repo in a selected base directory.

# Complex Examples

You might use this script to retrieve the latest changes from a remote working branch.

1. Run a clean across repos to get rid of extra files
2. Fetch remote branch updates (optional for this workflow)
3. Pull the latest code from your shared working branch

```gits clean; gits remote-update; gits pull -b my-working-branch```

You might also use this script to review changes in preparation for a commit to your feature branch

1. Run a clean to see only the files you'll want to commit
2. Check the status to confirm which repos you've touched
3. Confirm you're on your feature branch in the relevant repos

```gits clean; gits status; gits branch```

Then navigate to each repo and make your adds and commits.

# Installation

Place this ReadMe and the GitSync.ps1 PowerShell script in your root folder.

To improve usage, you can create an alias for GitSync and add it to your PowerShell profile. Just be aware that the alias will only work at the root directory (it'd take a little more to make it global).

```Set-Alias -Name gits -Value .\GitSync.ps1```

# Usage:

The following code snippets illustrate each of the available actions that can be taken with the GitSync.ps1 script, sorted alphabetically.

## Branch

```.\GitSync.ps1 -Action branch```

Displays the local branches for each repository. Useful to see what branch you're on for every branch and find where you may not have checked out the right branch.

[Branch Action](https://github.com/acbilson/ps-git-sync/images/action-branch.png)

## Branches

```.\GitSync.ps1 -Action branches```

Displays all remote branches that are relevant to your team. Useful to see the other branches your team have pushed. These are filtered with regex, so you may need to modify the regex to match your team's branch naming patterns. Don't forget to `.\GitSync.ps1 -Action Fetch` to update your local list of remote branches.

## Branches-Detailed

```.\GitSync.ps1 -Action branches-detailed -BranchHistory all```

A specialized request that returns the latest branches across all repositories using the same regex as the branches command. I found it helpful to identify when other feature branches have been pushed, such as a new feature branch from a colleague. The results default to all.

You may further filter the results by setting a new value for the BranchHistory parameter. Available values: "all", "two-weeks" and "today".

## Checkout

```.\GitSync.ps1 -Action checkout -Branch [BranchName]```

Checks out the specified branch across every repo. This is most useful to synchronize all repos to a single branch to confirm there are no build errors due to branch mismatches (which happens frequently when you're on different branches per repo). Does not check out a branch that doesn't exist.

## Clean

```.\GitSync.ps1 -Action clean```

This script cleans up the extra stuff created by the build process that we cannot hide with .gitignore or that's related to spark auto-generated files, and restores assembly version files that are part of the build process but only generate merge conflicts (have no dev value).

Be aware, the underlying git command runs clean with the -df flags.

## Fetch

```.\GitSync.ps1 -Action fetch```

Fetches the latest branch information across repositories. I use regex to strip out lengthy errors from broken branches so that new branches are more obviously reported. You may find this unnecessary and can simplify this part of the script if you'd like.

## Pull

```.\GitSync.ps1 -Action pull -Branch [BranchName]```

Checks out the specified branch, pulls the latest code from remote into that branch, then checks our your original branch (preserves current branch across repos). To use tab completion I've added our team's shared branches to the validation list - modify the list with your shared branches.

## Script

```.\GitSync.ps1 -Action script -Script {[do something here that happens in every repo]}```

This tool handles most circumstances, but when you need to run a command across all repos you can specify the command via the -Script tag. *USE WITH EXTREME CAUTION!!!* Do not run any command which makes modifications, for rolling back will be costly. If you find yourself running a command regularly with this method, consider adding it to one of this script's default actions instead.

## Status

```.\GitSync.ps1 -Action status```

Returns the status of all repositories. Run `.\GitSync.ps1 -Action Clean` (see below) first to view only your changes and not the extra cruft that's created by the build process. Very useful to verify that the changes you've made in your VS project do/do not touch another repository.

To distinguish modifications from new files, modifications are in yellow and new files are in red.

## Update-Remote

```.\GitSync.ps1 -Action update-remote```

Retrieves the latest remote branches and prunes (removes) any remote branches that have been deleted.