#!/usr/bin/env bash
# gitstatusd-lite: Lightweight gitstatusd replacement for powerlevel10k.
# Implements the same stdin/stdout protocol with \x1f field and \x1e record separators.
# Optimized to minimize subprocess spawns (5 git calls per request).
set -euo pipefail

# Accept all gitstatusd flags, ignore most.
while getopts "G:t:s:u:c:d:m:v:l:p:r:z:eUWD" opt; do
  case "$opt" in
  *) ;; # silently accept all flags
  esac
done

RS=$'\x1e'
FS=$'\x1f'

handle_request() {
  local req_id="$1" dir="$2" no_diff="${3:-0}"

  # Handle GIT_DIR prefix
  if [[ "$dir" == :* ]]; then
    dir="${dir#:}"
    export GIT_DIR="$dir"
  else
    unset GIT_DIR 2>/dev/null || true
  fi

  # Empty dir = not a repo (handles }hello handshake)
  if [[ -z "$dir" ]]; then
    printf '%s\x1f0\x1e' "$req_id"
    return
  fi

  # Combined rev-parse: workdir + git_dir_path (1 subprocess)
  # Also serves as repo validation — fails for non-repos.
  local rev_output
  rev_output="$(git -C "$dir" rev-parse --show-toplevel --absolute-git-dir 2>/dev/null)" || {
    printf '%s\x1f0\x1e' "$req_id"
    return
  }
  local workdir="${rev_output%%$'\n'*}"
  local git_dir_path="${rev_output##*$'\n'}"

  local commit="" local_branch="" remote_branch="" remote_name="" remote_url=""
  local action="" num_staged=0 num_unstaged=0 num_conflicted=0 num_untracked=0
  local commits_ahead=0 commits_behind=0 stashes=0 tag=""
  local num_unstaged_deleted=0 num_staged_new=0 num_staged_deleted=0
  local push_remote_name="" push_remote_url="" push_commits_ahead=0 push_commits_behind=0
  local commit_encoding="" commit_summary=""

  # --- Branch & commit from git internals (0 subprocesses) ---
  local head_content=""
  [[ -f "$git_dir_path/HEAD" ]] && head_content=$(<"$git_dir_path/HEAD")

  if [[ "$head_content" == "ref: refs/heads/"* ]]; then
    local_branch="${head_content#ref: refs/heads/}"
    local ref_file="$git_dir_path/refs/heads/$local_branch"
    if [[ -f "$ref_file" ]]; then
      commit=$(<"$ref_file")
    elif [[ -f "$git_dir_path/packed-refs" ]]; then
      while IFS= read -r packed_line; do
        [[ "$packed_line" == "#"* || "$packed_line" == "^"* ]] && continue
        [[ "$packed_line" == *" refs/heads/$local_branch" ]] && commit="${packed_line%% *}" && break
      done <"$git_dir_path/packed-refs"
    fi
  elif [[ -n "$head_content" ]]; then
    commit="$head_content"
  fi

  # --- All config in one call (1 subprocess) ---
  if [[ -n "$local_branch" ]]; then
    local config_output
    config_output="$(git -C "$dir" config --get-regexp '^(branch\.|remote\.)' 2>/dev/null)" || true

    if [[ -n "$config_output" ]]; then
      local cfg_line
      while IFS= read -r cfg_line; do
        case "$cfg_line" in
        "branch.${local_branch}.remote "*) remote_name="${cfg_line##* }" ;;
        "branch.${local_branch}.merge "*)
          remote_branch="${cfg_line##* }"
          remote_branch="${remote_branch#refs/heads/}"
          ;;
        "branch.${local_branch}.pushRemote "*) push_remote_name="${cfg_line##* }" ;;
        "remote.pushDefault "*) [[ -z "$push_remote_name" ]] && push_remote_name="${cfg_line##* }" ;;
        esac
      done <<<"$config_output"

      # Remote URLs from same config output
      if [[ -n "$remote_name" ]]; then
        while IFS= read -r cfg_line; do
          [[ "$cfg_line" == "remote.${remote_name}.url "* ]] && remote_url="${cfg_line#* }" && break
        done <<<"$config_output"
      fi
      if [[ -n "$push_remote_name" ]]; then
        while IFS= read -r cfg_line; do
          [[ "$cfg_line" == "remote.${push_remote_name}.url "* ]] && push_remote_url="${cfg_line#* }" && break
        done <<<"$config_output"
      fi
    fi
  fi

  # --- Ahead/behind upstream (1 subprocess, skip rev-parse verify) ---
  if [[ -n "$remote_name" && -n "$remote_branch" ]]; then
    local ab
    ab="$(git -C "$dir" rev-list --left-right --count "refs/remotes/${remote_name}/${remote_branch}...HEAD" 2>/dev/null)" || true
    if [[ -n "$ab" ]]; then
      commits_behind="${ab%%$'\t'*}"
      commits_ahead="${ab##*$'\t'}"
    fi
  fi

  # --- Action: inline file checks (0 subprocesses) ---
  if [[ -d "$git_dir_path/rebase-merge" || -d "$git_dir_path/rebase-apply" ]]; then
    action="rebase"
  elif [[ -f "$git_dir_path/MERGE_HEAD" ]]; then
    action="merge"
  elif [[ -f "$git_dir_path/CHERRY_PICK_HEAD" ]]; then
    action="cherry-pick"
  elif [[ -f "$git_dir_path/REVERT_HEAD" ]]; then
    action="revert"
  elif [[ -f "$git_dir_path/BISECT_LOG" ]]; then
    action="bisect"
  fi

  # --- Stash count from file (0 subprocesses) ---
  if [[ -f "$git_dir_path/logs/refs/stash" ]]; then
    stashes=$(wc -l <"$git_dir_path/logs/refs/stash")
    stashes="${stashes// /}"
  fi

  # --- Tag from refs (0 subprocesses) ---
  if [[ -n "$commit" ]]; then
    # Check loose tag refs
    if [[ -d "$git_dir_path/refs/tags" ]]; then
      local tag_file
      for tag_file in "$git_dir_path/refs/tags/"*; do
        [[ -f "$tag_file" ]] || continue
        [[ "$(<"$tag_file")" == "$commit"* ]] && tag="${tag_file##*/}" && break
      done
    fi
    # Check packed-refs
    if [[ -z "$tag" && -f "$git_dir_path/packed-refs" ]]; then
      local packed_line
      while IFS= read -r packed_line; do
        [[ "$packed_line" == "#"* ]] && continue
        [[ "$packed_line" == "$commit refs/tags/"* ]] && tag="${packed_line##*/}" && break
      done <"$git_dir_path/packed-refs"
    fi
  fi

  # --- Push remote ahead/behind (0-1 subprocesses) ---
  if [[ -n "$push_remote_name" && -n "$local_branch" ]]; then
    local push_ab
    push_ab="$(git -C "$dir" rev-list --left-right --count "refs/remotes/${push_remote_name}/${local_branch}...HEAD" 2>/dev/null)" || true
    if [[ -n "$push_ab" ]]; then
      push_commits_behind="${push_ab%%$'\t'*}"
      push_commits_ahead="${push_ab##*$'\t'}"
    fi
  fi

  # --- Commit encoding + summary combined (1 subprocess) ---
  if [[ -n "$commit" ]]; then
    local log_output
    log_output="$(git -C "$dir" log -1 --format='%e%x01%s' HEAD 2>/dev/null)" || true
    if [[ -n "$log_output" ]]; then
      commit_encoding="${log_output%%$'\x01'*}"
      commit_summary="${log_output#*$'\x01'}"
      commit_summary="${commit_summary:0:256}"
    fi
  fi

  # Emit response: req_id \x1f 1 \x1f field0 \x1f ... \x1f field26 \x1e
  printf '%s\x1f1' "$req_id"
  printf '\x1f%s' \
    "$workdir" "$commit" "$local_branch" "$remote_branch" \
    "$remote_name" "$remote_url" "$action" \
    "0" "$num_staged" "$num_unstaged" \
    "$num_conflicted" "$num_untracked" \
    "$commits_ahead" "$commits_behind" \
    "$stashes" "$tag" \
    "$num_unstaged_deleted" "$num_staged_new" "$num_staged_deleted" \
    "$push_remote_name" "$push_remote_url" \
    "$push_commits_ahead" "$push_commits_behind" \
    "0" "0" \
    "$commit_encoding" "$commit_summary"
  printf '\x1e'
}

# Main loop: read \x1e-terminated records from stdin
while IFS= read -r -d "$RS" request; do
  IFS="$FS" read -r -a fields <<<"$request"

  req_id="${fields[0]:-}"
  dir="${fields[1]:-}"
  no_diff="${fields[2]:-0}"

  handle_request "$req_id" "$dir" "$no_diff"
done
