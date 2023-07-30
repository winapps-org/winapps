# Contribution Guidelines

Thank you for contributing to winapps! Before you can contribute, we ask some things of you:

- Please follow our Code of Conduct, the Contributor Covenant. You can find a copy in this repository or under https://www.contributor-covenant.org/
- All Contributors have to sign [a CLA](https://gist.github.com/oskardotglobal/35f0a72eb45fcc7087e535561383dbc5) for legal reasons. When opening a PR, @cla-assitant will prompt you and guide you through the process. However, if you contribute on behalf of a legal entity, we ask of you to sign [a different CLA](https://gist.github.com/oskardotglobal/75a8cc056e56a439fa6a1551129ae47f). In that case, please contact us.

## How to contribute

- Fork this repository
- Create a new branch with a descriptive name
- Make your changes
- Install and run `pre-commit` (see below)
- Open a Pull Request

## Pre-commit

pre-commit is a tool which allows to run checks before committing.
It is recommended to install it and run it before committing, since the same checks
are run through github actions on pull request. We will not merge a pull request unless all checks pass.

Installation instructions can be found here: https://pre-commit.com/#install <br>
After installing, run `pre-commit install` in the repository root to install the git hooks.

It is recommended to run `pre-commit run --all-files` before committing to make sure all checks pass.  It is also recommended to use the git cli since graphical git solutions do not always play well with pre-commit.
