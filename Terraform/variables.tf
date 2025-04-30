
#variable "github_pat" {
#  description = "GitHub Personal Access Token"
#  sensitive   = true
#}
#

variable "github_owner" {
  description = "GitHub Personal Access Token with 'repo' and 'admin:repo_hook' permissions"
  default   = "dhiemer"
}

variable "github_repo" {
  description = "github_repo"
  default   = "https://github.com/dhiemer/earthquake-monitor"
}

