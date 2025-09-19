#!/bin/sh
# phonefetch - small Winfetch-like info script with a custom Apple logo (user-provided)
# POSIX sh compatible; runs in Alpine/iSH (ash) and similar shells.

# --- Helpers ---
esc() { printf "\033[%sm" "$1"; }
reset() { esc 0; }

# color defs
BOLD="1"
RED="31"
GREEN="32"
YELLOW="33"
BLUE="34"
MAG="35"
CYAN="36"
WHITE="37"

# gather info with safe fallbacks
get_os() {
  if [ -r /etc/os-release ]; then
    . /etc/os-release
    printf "%s" "${PRETTY_NAME:-$NAME}"
  elif command -v lsb_release >/dev/null 2>&1; then
    lsb_release -ds
  else
    uname -s
  fi
}

get_kernel() { uname -r 2>/dev/null || printf "unknown"; }
get_arch() { uname -m 2>/dev/null || printf "unknown"; }
get_uptime() {
  if command -v uptime >/dev/null 2>&1; then
    uptime -p 2>/dev/null | sed 's/up //'
  elif [ -r /proc/uptime ]; then
    secs=$(cut -d. -f1 /proc/uptime)
    days=$((secs/86400)); hrs=$(( (secs%86400)/3600)); mins=$(( (secs%3600)/60 ))
    out=""
    [ "$days" -gt 0 ] && out="$out${days}d "
    [ "$hrs" -gt 0 ] && out="$out${hrs}h "
    [ "$mins" -gt 0 ] && out="$out${mins}m"
    printf "%s" "${out:-0m}"
  else
    printf "unknown"
  fi
}

get_shell() { printf "%s" "${SHELL:-$(ps -p $$ -o comm= 2>/dev/null) }"; }
get_pkgs() {
  if command -v apk >/dev/null 2>&1; then
    apk info | wc -l
  elif command -v dpkg >/dev/null 2>&1; then
    dpkg --list | wc -l
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Q | wc -l
  else
    printf "n/a"
  fi
}

get_host() { hostname 2>/dev/null || printf "unknown"; }

# --- ASCII Apple logo (user-provided) ---
apple_logo() {
cat <<'APPLE'
                        .8 
                      .888
                    .8888'
                   .8888'
                   888'
                   8'
      .88888888888. .88888888888.
   .8888888888888888888888888888888.
 .8888888888888888888888888888888888.
.&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&'
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
`%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%.
 `00000000000000000000000000000000000'
  `000000000000000000000000000000000'
   `0000000000000000000000000000000'
     `###########################'
     `#######################' 
         `#########''########'
           `""""""'  `"""""'
APPLE
}

# --- Output formatting ---
os=$(get_os)
kernel=$(get_kernel)
arch=$(get_arch)
uptime=$(get_uptime)
shell=$(get_shell)
pkgs=$(get_pkgs)
host=$(get_host)
user=$(id -un 2>/dev/null || printf "%s" "$USER")

# left-col logo, right-col info
logo="$(apple_logo)"
# build info block
info="$(printf "%s\n" \
  "$(esc ${BOLD}; esc ${CYAN})${user}@${host}$(reset)" \
  "$(esc ${GREEN})OS: $(reset)${os}" \
  "$(esc ${GREEN})Kernel: $(reset)${kernel} (${arch})" \
  "$(esc ${GREEN})Uptime: $(reset)${uptime}" \
  "$(esc ${GREEN})Shell: $(reset)${shell}" \
  "$(esc ${GREEN})Packages: $(reset)${pkgs}")"

# print side-by-side (logo left, info right)
# choose column widths
logo_lines=$(printf "%s\n" "$logo" | wc -l)
info_lines=$(printf "%s\n" "$info" | wc -l)
lines=$(( logo_lines > info_lines ? logo_lines : info_lines ))

paste_output=''
i=1
while :; do
  l_line=$(printf "%s\n" "$logo" | sed -n "${i}p")
  r_line=$(printf "%s\n" "$info" | sed -n "${i}p")
  [ -z "$l_line" ] && l_line=" "
  [ -z "$r_line" ] && r_line=" "
  # pad logo column (width 28 to fit wider art)
  printf -v padded "%-28s" "$l_line" 2>/dev/null || padded=`printf "%-28s" "$l_line"`
  paste_output="${paste_output}${padded}  ${r_line}\n"
  i=$((i+1))
  [ $i -gt $lines ] && break
done

# print with final reset
printf "%b" "$paste_output"
reset
