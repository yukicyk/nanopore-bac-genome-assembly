# Contributing to the Bacterial Genome Assembly Pipeline

First off, thank you for considering contributing to this project! Your help is greatly appreciated. Whether you're reporting a bug, suggesting a new feature, or submitting code, every contribution helps make this pipeline better for everyone.

This document provides guidelines for contributing to the project.

## Code of Conduct

This project and everyone participating in it is governed by a [Code of Conduct](link-to-your-code-of-conduct-file.md). By participating, you are expected to uphold this code. Please report unacceptable behavior. (Note: You can easily add a standard Code of Conduct file. The "Contributor Covenant" is a popular choice and can be added from the "Add File" -> "New File" menu on GitHub, which will offer it as a template).

## How Can I Contribute?

There are several ways you can contribute to this project:

### Reporting Bugs

If you find a bug, please ensure it hasn't already been reported by searching the [Issues](https://github.com/yukicyk/nanopore-bac-genome-assembly/issues) on GitHub.

If you're unable to find an open issue addressing the problem, please [open a new one](https://github.com/yukicyk/nanopore-bac-genome-assembly/issues/new). Be sure to include:
- A **clear and descriptive title**.
- A **detailed description** of the problem.
- The **exact command** you used to run Snakemake.
- The **full error message** and traceback from the Snakemake log.
- The version of Snakemake and Conda/Mamba you are using.
- Information about your operating system.

### Suggesting Enhancements

If you have an idea for a new feature or an improvement to an existing one:
1.  Check the [Issues](https://github.com/yukicyk/nanopore-bac-genome-assembly/issues) to see if your idea has already been discussed.
2.  If not, open a new issue, providing a clear title and a detailed description of the proposed enhancement and why it would be valuable.

### Submitting Pull Requests

If you would like to contribute code, please follow these steps:

1.  **Fork the Repository:**
    Click the "Fork" button at the top right of this page to create your own copy of the repository.

2.  **Clone Your Fork:**
    Clone your forked repository to your local machine.
    ```bash
    git clone https://github.com/your-username/nanopore-bac-genome-assembly.git
    cd nanopore-bac-genome-assembly
    ```

3.  **Create a New Branch:**
    Create a new branch for your changes. Use a descriptive name.
    ```bash
    # For a new feature
    git checkout -b feature/add-bakta-annotation

    # For a bug fix
    git checkout -b bugfix/fix-pilon-memory-issue
    ```

4.  **Make Your Changes:**
    - Write your code.
    - If you add a new tool, create a new Conda environment file in `pipeline/envs/`.
    - If you modify the workflow, please update the relevant documentation in the `/docs` folder (e.g., `SOP_ONT_bacterial_WGS.md`).

5.  **Test Your Changes:**
    - Before submitting, please ensure your changes do not break the existing workflow.
    - Run a full dry-run and, if possible, a test run on a small dataset.
    ```bash
    # Ensure the CI checks will pass
    snakemake -n --use-conda -s pipeline/Snakefile
    ```

6.  **Commit and Push:**
    Commit your changes with a clear and concise commit message, then push them to your fork.
    ```bash
    git commit -m "feat: Add Bakta as an alternative annotation tool"
    git push origin feature/add-bakta-annotation
    ```

7.  **Open a Pull Request:**
    - Go to your forked repository on GitHub and click the "Contribute" button, then "Open pull request".
    - Provide a detailed description of the changes you've made.
    - The CI workflow will automatically run. Please ensure all checks pass. Your PR will be reviewed once the checks are complete.

Thank you again for your contribution!