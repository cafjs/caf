# Contributing Guidelines

The `Caf.js` project accepts contributions using Github pull requests. This document describes how to get your contribution accepted.

## Sign-Off Your Work

We follow the Linux source convention of signing-off each commit by adding a single line at the end of your commit explanation, for example:

    Signed-off-by: Joe Smith <joe.smith@example.com>

Use your real name (sorry, no pseudonyms or anonymous contributions.)

What this means is that your contribution agrees with the DCO (Developer Certificate of Origin 1.1) from [developercertificate.org](http://developercertificate.org/)), i.e., you wrote the patch or otherwise have the right to contribute the material, and you are happy with the current license (Apache 2.0).

The simplest way to add the line to all commits is to use the `-s` option in `git commit`, after configuring once your name and email in git:

    git config user.name "Legal Name"
    git config user.email "email@domain"

and then for each commit:

    git commit -s -m "Fix typo in docs"

If you forgot to add the sign-off you can amend the previous commit with `git commit --amend -s` and, if the changes were already pushed to github, force push your branch with `git push -f`.
