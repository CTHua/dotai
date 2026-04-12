_dotai_dir="${${(%):-%N}:A:h}"
_dotai_interval="${DOTAI_UPDATE_INTERVAL_SECONDS:-600}"
_dotai_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotai"
_dotai_last_check_file="$_dotai_cache_dir/last-check"
_dotai_lock_dir="$_dotai_cache_dir/update.lock"

(
  _dir="$_dotai_dir"
  mkdir -p "$_dotai_cache_dir" 2>/dev/null || exit 0

  _now=$(date +%s 2>/dev/null) || exit 0
  if [[ -f "$_dotai_last_check_file" ]]; then
    _last_check=$(<"$_dotai_last_check_file")
    if [[ "$_last_check" == <-> ]] && (( _now - _last_check < _dotai_interval )); then
      exit 0
    fi
  fi

  mkdir "$_dotai_lock_dir" 2>/dev/null || exit 0
  trap 'rmdir "$_dotai_lock_dir" >/dev/null 2>&1' EXIT
  print -r -- "$_now" > "$_dotai_last_check_file" 2>/dev/null || exit 0

  git -C "$_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
  git -C "$_dir" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1 || exit 0

  if [[ -n "$(git -C "$_dir" status --porcelain 2>/dev/null)" ]]; then
    printf '\033[0;33m[dotai]\033[0m Local uncommitted changes detected, skipping auto-update\n'
    exit 0
  fi

  git -C "$_dir" fetch --quiet 2>/dev/null || exit 0
  _local=$(git -C "$_dir" rev-parse HEAD 2>/dev/null) || exit 0
  _remote=$(git -C "$_dir" rev-parse @{u} 2>/dev/null) || exit 0

  if [[ "$_local" != "$_remote" ]]; then
    if git -C "$_dir" pull --ff-only --quiet 2>/dev/null; then
      bash "$_dir/install.sh" 2>/dev/null | grep -v '^ '
      printf '\033[0;32m[dotai]\033[0m Auto-updated and installed\n'
    fi
  else
    bash "$_dir/sync-external.sh" 2>/dev/null | grep -v '^ '
    bash "$_dir/sync-mcp.sh" 2>/dev/null | grep -v '^ '
  fi
) &!

unset _dotai_dir
unset _dotai_interval
unset _dotai_cache_dir
unset _dotai_last_check_file
unset _dotai_lock_dir
