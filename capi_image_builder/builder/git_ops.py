from pathlib import Path
from typing import Optional

from git import Repo


class GitOps:
    """
    A class which handles git operations on behalf of the builder.
    """

    def __init__(self, ssh_key_path: Path):
        self.ssh_key_path = ssh_key_path
        self.repo: Optional[Repo] = None

    def git_clone(self, repo_url, target_dir: Path) -> Repo:
        """Clone a git repo to a target directory."""
        self._validate_protocol(repo_url)
        print(f"Cloning {repo_url} to {target_dir}")
        self.repo = Repo.clone_from(
            repo_url, target_dir, env={"GIT_SSH_COMMAND": f"ssh -i {self.ssh_key_path}"}
        )
        return self.repo

    def set_git_username(self, username: str):
        """Set the username for the git repo."""
        self.repo.config_writer().set_value("user", "name", username).release()

    def set_git_email(self, email: str):
        """Set the email for the git repo."""
        self.repo.config_writer().set_value("user", "email", email).release()

    @staticmethod
    def _validate_protocol(repo_url):
        if not repo_url.startswith("git@"):
            raise ValueError("SSH key provided, but repo URL is not SSH")

    def git_add_upstream(self, upstream_url: str, remote_name: str = "upstream"):
        """Add an upstream remote to a git repo."""
        self.repo.create_remote(remote_name, upstream_url)

    def git_fetch_upstream(self, remote_name: str = "upstream"):
        """Fetch the upstream remote of a git repo."""
        self.repo.remotes[remote_name].fetch()

    def git_merge_upstream(self, remote_name: str = "upstream", branch: str = "master"):
        """
        Merge the current branch onto the upstream branch to bring fork into sync.
        """
        print(f"Merging {remote_name}/{branch} into current branch")
        self.repo.git.merge(f"{remote_name}/{branch}")

    def git_push(self, remote_name: str = "origin", branch: str = "master"):
        """Push the current branch to the remote."""
        print(f"Pushing current branch to {remote_name}/{branch}")
        self.repo.git.push(remote_name, branch)
