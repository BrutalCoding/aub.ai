# AubAI Contribution Guide [![GitHub stars](https://img.shields.io/github/stars/brutalcoding/aub.ai.svg?style=social&label=Star&maxAge=2592000)](https://github.com/brutalcoding/aub.ai/stargazers) [![License](https://img.shields.io/badge/license-AGPL--3.0-blue)](https://github.com/brutalcoding/aub.ai/blob/main/LICENSE)

The `AubAI` community warmly welcomes your contribution. To streamline the process, we recommend you follow this contribution guide closely.

## Development Workflow

Begin by forking the AubAI GitHub repository, create changes in a branch, and then submit a pull request. We encourage pull requests to facilitate code discussion. Detailed steps are explained below.

### Setup your AubAI GitHub Repository

Fork the [AubAI upstream](https://github.com/brutalcoding/aub.ai/fork) source repository to your personal repository. Copy your AubAI fork's URL (needed for the `git clone` command below).

```sh
git clone https://github.com/YOUR_USERNAME/aub.ai
cd aub.ai
git remote add upstream https://github.com/brutalcoding/aub.ai
git fetch upstream
git merge upstream/main
```

### Create a Branch

Create a branch for your changes. We recommend using a branch name that describes your changes. For example, if you are adding a new feature, you should name your branch `feature/your-feature-name`. If you are fixing something, consider using `fix/your-fix-name`.

```sh
git checkout -b feature/your-feature-name
```

### Make Changes

Make your changes to the codebase. We recommend you follow the [conventional commit message format](<https://www.conventionalcommits.org/en/v1.0.0/>).

For example, if you are adding a new feature, you could use the following commit message:

```sh
git add .
git commit -m "docs: Create a contribution guide"
```

or if you are fixing a bug, you could use the following commit message:

```sh
git add .
git commit -m "fix: Fix the bug that prevented the Flutter example from running on Android"
```

### Push Changes

Push your changes to your forked AubAI repository.

```sh
git push origin feature/your-feature-name
```

### Submit a Pull Request

Submit a pull request from your forked AubAI repository to the AubAI upstream repository. We will review your pull request and merge it if it meets our requirements.

## Code of conduct

AubAI is a community project. We want to make sure that everyone feels welcome and safe. We expect everyone to follow the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md).
