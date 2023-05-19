from pathlib import Path
from tempfile import mkdtemp

from args import Args
from builder.git_ops import GitOps

K8S_FORK_URL = "git@github.com:stfc/k8s-image-builder.git"
UPSTREAM_URL = "https://github.com/kubernetes-sigs/image-builder.git"


def populate_temp_dir(arg: Args) -> Args:
    """
    Creates a temporary directory if one is not provided and ensures
    the target directory exists.
    """
    if arg.target_dir is None:
        arg.is_tmp_dir = True
        arg.target_dir = mkdtemp()
        print(f"Using temporary directory: {arg.target_dir}")

    target_dir = Path(arg.target_dir)
    if not target_dir.exists():
        target_dir.mkdir()

    return arg


def clone_repo(args: Args) -> GitOps:
    """
    Clones the repo to the target directory.
    """
    args = populate_temp_dir(args)
    ops = GitOps(Path(args.ssh_key_path))
    ops.git_clone(K8S_FORK_URL, Path(args.target_dir))
    return ops


def checkout_branch(ops: GitOps, branch: str):
    """
    Checks out the branch to build the image from.
    """
    print(f"Checking out branch {branch}")
    ops.repo.git.checkout(branch)


def update_repo(ops: GitOps, push: bool):
    """
    Clones and merges the repo to sync upstream updates.
    """
    ops.git_add_upstream(UPSTREAM_URL)
    ops.git_fetch_upstream()
    ops.git_merge_upstream()
    if push:
        ops.git_push()


def prepare_image_repo(args: Args):
    """
    Prepares the image repo for building, this includes cloning the repo and
    merging it to sync with upstream changes.
    """
    ops = clone_repo(args)
    checkout_branch(ops, args.git_branch)
    update_repo(ops, args.push_to_github)
