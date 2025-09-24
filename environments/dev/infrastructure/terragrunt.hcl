# Development Infrastructure - All-in-One Deployment

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = find_in_parent_folders("env.hcl")
  merge_strategy = "deep"
}

terraform {
  source = "${get_path_to_repo_root()}//modules/infrastructure"
}