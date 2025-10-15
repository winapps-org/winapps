# Contribution Guidelines

Thank you for contributing to winapps! Before you can contribute, we ask some things of you:

- Please follow our Code of Conduct, the Contributor Covenant. You can find a copy in this repository or under https://www.contributor-covenant.org/
- All Contributors have to sign a Developer Certificate of Origin, agreeing to license their contribution under the AGPLv3. Historically, we used to require a CLA because we had to relicense the codebase from ARR to AGPLv3; however, this is being phased out. You can find a copy of the DCO below or under https://developercertificate.org/.
- Please follow code conventions enforced by `pre-commit`. To keep down CI usage, please run it locally before committing too.
  See <https://pre-commit.com> for installation, then run `pre-commit install` inside the `winapps` repository you cloned.

## About using Artificial Intelligence for pull requests

> [!IMPORTANT]
> If you are using any kind of AI assistance to contribute to WinApps, it must be disclosed in the pull request.

### AI-generated code

When using AI assistance, we expect contributors to understand the code that is produced and be able to answer critical questions about it. It isn't a maintainers job to review a PR so broken that it requires significant rework to be acceptable. In a perfect world, AI assistance would produce equal or higher quality work than any human. That isn't the world we live in today, and in most cases it's generating slop. A good rule of thumb is that if another person can easily tell a pull request is AI-generated, it needs some more work.

### Other kinds of AI assistance

Currently, [CodeRabbit](https://coderabbit.ai) is configured to review pull requests *on demand* when `@coderabbitai review` is commented on pull requests.
However, we ask of you to not use it for PRs of which you are the authors unless asked to. Additionally, please do not AI-generate descriptions for larger pull requests or reviews by hand. This does not include things like commit messages.

### AI "Art"

We do not condone AI-generated "art", including AI-written and AI-produced tutorials, AI-generated icons for contributed applications.
Additionally, please do not share these kinds of media on any official WinApps channel.

## Guidelines for pre-defined applications

Some pre-defined applications contain a header like:

```
# Copyright (c) 2024 Fmstrat
# All rights reserved.
#
# SPDX-License-Identifier: Proprietary
```

This is for historic reasons, see [LICENSE.md](../LICENSE.md) and [COPYRIGHT.md](../COPYRIGHT.md).
When contributing new applications, please *do not* include such a header.

## Developer Certificate of Origin

Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
