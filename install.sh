#!/usr/bin/env bash
#
# install.sh - bootstrap this GNU Stow managed dotfiles repository on
#              Arch Linux (and derivatives) or Fedora Linux (and derivatives).
#
# Package source priority
#   Arch:   official repositories -> AUR -> official upstream fallback
#   Fedora: enabled DNF repositories -> relevant third-party repositories
#           (RPM Fusion) -> COPR -> official upstream fallback
#
# The script never adopts or overwrites existing user configuration.  Before
# any link is created it runs `stow --simulate`; conflicts abort the Stow step.
#
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR

# The configuration puts user-local binaries on PATH; make sure any wrapper
# installed by this script is visible to the verification step too.
export PATH="$HOME/.local/bin:$PATH"

# Directories in this repository that GNU Stow should manage.
# rofi, ytm and zed were intentionally removed from the repository.
readonly STOW_PACKAGES=(
    .themes
    btop
    DankMaterialShell
    fish
    ghostty
    mpv
    neofetch
    niri
    noctalia
    paru
    scripts
    starship
    systemd
    tmux
    vesktop
)

# Packages removed from active tracking.  Only symlinks that point back into
# this repository are cleaned up; real user files are never touched.
readonly REMOVED_PACKAGES=(rofi ytm zed)

# ---------------------------------------------------------------------------
# Arch Linux package lists (verified against archlinux.org and AUR RPC)
# ---------------------------------------------------------------------------
readonly ARCH_OFFICIAL=(
    # bootstrap / script helpers
    stow git curl unzip jq fontconfig
    # desktop session
    niri noctalia dux-shell foot ghostty
    # shell and terminal tooling
    fish starship zoxide fzf eza yazi tmux neovim btop lazygit fastfetch
    bat fd ripgrep
    # Wayland helpers used by the configuration
    wl-clipboard wtype fuzzel libnotify
    # theming / portals / session integration
    adw-gtk-theme ttf-jetbrains-mono-nerd
    nautilus gnome-keyring polkit xdg-utils
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
    xwayland-satellite pipewire wireplumber networkmanager bluez bluez-utils upower
    plasma-integration matugen
    # media
    mpv ffmpeg yt-dlp python-guessit spotify-launcher
    playerctl pamixer brightnessctl wf-recorder grim slurp
)

readonly ARCH_AUR=(
    # fonts used by Noctalia / DankMaterialShell
    ttf-google-sans
    ttf-google-sans-flex-variable
    # cursor theme referenced by niri
    bibata-cursor-theme-bin
    # launcher / session helpers that are AUR-only on Arch
    app2unit helium-browser-bin vicinae-bin
    # applications referenced by the configuration
    vesktop-bin neofetch
)

# ---------------------------------------------------------------------------
# Fedora package lists (verified against enabled Fedora repositories)
# ---------------------------------------------------------------------------
readonly FEDORA_OFFICIAL=(
    # bootstrap / script helpers
    stow git curl unzip jq fontconfig dnf-plugins-core
    # desktop session
    niri noctalia DankMaterialShell foot
    # shell and terminal tooling
    fish zoxide fzf eza tmux neovim btop fastfetch bat fd-find ripgrep
    # Wayland helpers used by the configuration
    wl-clipboard wtype fuzzel libnotify
    # fonts / theming / portals / session integration
    adw-gtk3-theme jetbrains-mono-fonts-all
    google-noto-sans-fonts google-noto-sans-mono-fonts google-noto-color-emoji-fonts
    nautilus gnome-keyring polkit xdg-utils
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
    xwayland-satellite pipewire wireplumber NetworkManager bluez upower
    plasma-integration matugen
    # media
    mpv ffmpeg-free yt-dlp python3-guessit
    playerctl pamixer brightnessctl wf-recorder grim slurp
)

# Packages that are not in the default Fedora repositories.  Each entry is
# "package -> COPR project".  The installer still checks the enabled DNF
# repositories first, then enables the COPR only if the package is missing.
declare -A FEDORA_COPR=(
    [starship]="atim/starship"
    [lazygit]="dejan/lazygit"
    [app2unit]="celestelove/app2unit"
    [ghostty]="duxlabs/dux-repo"
    [vicinae]="scottames/vicinae"
    [helium-bin]="imput/helium"
    [bibata-cursor-themes]="peterwu/rendezvous"
    [yazi]="lihaohong/yazi"
)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
DRY_RUN=0
DO_PACKAGES=1
DO_STOW=1
INSTALL_FONTS=1
DISTRO=""
DISTRO_NAME=""
SUDO_OK=0
AUR_HELPER=""
FAILURES=()
WARNINGS=()
MANUAL_STEPS=()
TMP_DIRS=()

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RESET=$'\033[0m'
    C_INFO=$'\033[1;34m'
    C_OK=$'\033[1;32m'
    C_WARN=$'\033[1;33m'
    C_ERR=$'\033[1;31m'
else
    C_RESET=""
    C_INFO=""
    C_OK=""
    C_WARN=""
    C_ERR=""
fi

info() { printf '%s==>%s %s\n' "$C_INFO" "$C_RESET" "$*"; }
ok()   { printf '%s ok %s %s\n' "$C_OK" "$C_RESET" "$*"; }
warn() {
    printf '%swarn%s %s\n' "$C_WARN" "$C_RESET" "$*" >&2
    WARNINGS+=("$*")
}
error() { printf '%serr %s %s\n' "$C_ERR" "$C_RESET" "$*" >&2; }
fail() {
    error "$*"
    FAILURES+=("$*")
}
manual() { MANUAL_STEPS+=("$*"); }

cleanup() {
    trap - ERR
    local dir
    for dir in "${TMP_DIRS[@]:-}"; do
        if [[ -n "$dir" ]]; then
            rm -rf -- "$dir"
        fi
    done
    return 0
}
trap cleanup EXIT

trap 'error "Unexpected failure at line $LINENO: $BASH_COMMAND"' ERR

usage() {
    cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Install the packages required by these dotfiles and link the Stow packages
into $HOME.

Options:
  --dry-run        Show what would be done without changing the system
  --no-packages    Skip package installation (Stow only)
  --stow-only      Alias for --no-packages
  --no-stow        Install packages but do not run GNU Stow
  --skip-fonts     Do not download user-local fallback fonts
  -h, --help       Show this help

Supported systems:
  Arch Linux and derivatives (pacman + optional AUR helper)
  Fedora Linux and derivatives (dnf + COPR)

Notes:
  * Run as your normal user, not as root.  sudo is requested when needed.
  * Existing user files are never adopted or overwritten.  Stow conflicts
    are reported and the Stow step is aborted.
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing / environment
# ---------------------------------------------------------------------------
parse_args() {
    while (($#)); do
        case "$1" in
            --dry-run) DRY_RUN=1 ;;
            --no-packages|--stow-only) DO_PACKAGES=0 ;;
            --no-stow) DO_STOW=0 ;;
            --skip-fonts) INSTALL_FONTS=0 ;;
            -h|--help) usage; exit 0 ;;
            *)
                error "Unknown option: $1"
                usage
                exit 2
                ;;
        esac
        shift
    done

    if ((DO_PACKAGES == 0)); then
        INSTALL_FONTS=0
    fi
}

detect_distro() {
    if [[ ! -r /etc/os-release ]]; then
        error "/etc/os-release is missing; unsupported system."
        exit 1
    fi

    # shellcheck disable=SC1091
    local id like pretty name
    id=""
    like=""
    pretty=""
    name=""
    # shellcheck source=/dev/null
    . /etc/os-release
    id="${ID:-}"
    like="${ID_LIKE:-}"
    pretty="${PRETTY_NAME:-${NAME:-$id}}"
    name="${NAME:-$id}"

    case "$id" in
        arch|archlinux|endeavouros|manjaro|cachyos|garuda)
            DISTRO="arch" ;;
        fedora|nobara)
            DISTRO="fedora" ;;
        *)
            case " $like " in
                *arch*) DISTRO="arch" ;;
                *fedora*|*rhel*) DISTRO="fedora" ;;
                *)
                    error "Unsupported distribution: $pretty"
                    error "Supported: Arch Linux (and derivatives) or Fedora Linux (and derivatives)."
                    exit 1
                    ;;
            esac
            ;;
    esac

    DISTRO_NAME="$pretty"
}

require_sudo() {
    if ((SUDO_OK == 1)); then
        return 0
    fi
    if ((DRY_RUN == 1)); then
        SUDO_OK=1
        return 0
    fi
    if ((EUID == 0)); then
        error "Do not run this script as root. Run it as your normal user; sudo is used when needed."
        exit 1
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        error "sudo is required to install packages."
        exit 1
    fi
    info "Requesting sudo privileges..."
    if ! sudo -v; then
        error "sudo authentication failed."
        exit 1
    fi
    SUDO_OK=1
}

run() {
    if ((DRY_RUN == 1)); then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi
    "$@"
}

run_sudo() {
    require_sudo
    run sudo "$@"
}

mktemp_dir() {
    local dir
    dir="$(mktemp -d)"
    TMP_DIRS+=("$dir")
    printf '%s\n' "$dir"
}

# ---------------------------------------------------------------------------
# Arch Linux
# ---------------------------------------------------------------------------
arch_pkg_installed() {
    if [[ "$1" == "base-devel" ]]; then
        pacman -Qgq base-devel >/dev/null 2>&1
    else
        pacman -Qq "$1" >/dev/null 2>&1
    fi
}

arch_pkg_available() {
    pacman -Si "$1" >/dev/null 2>&1 || pacman -Sg "$1" >/dev/null 2>&1
}

arch_install_official() {
    local -a missing=()
    local pkg

    for pkg in "$@"; do
        arch_pkg_installed "$pkg" || missing+=("$pkg")
    done

    if ((${#missing[@]} == 0)); then
        return 0
    fi

    info "Installing Arch official packages: ${missing[*]}"
    if run_sudo pacman -S --needed --noconfirm "${missing[@]}"; then
        return 0
    fi

    warn "Batch pacman install failed; retrying packages individually."
    local failed=0
    for pkg in "${missing[@]}"; do
        if ! run_sudo pacman -S --needed --noconfirm "$pkg"; then
            fail "pacman failed to install: $pkg"
            failed=1
        fi
    done
    return "$failed"
}

aur_pkg_available() {
    local pkg="$1" response
    if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        return 0
    fi
    if ! response="$(curl -fsSL --max-time 20 "https://aur.archlinux.org/rpc/v5/info?arg[]=$pkg" 2>/dev/null)"; then
        return 0
    fi
    jq -e --arg p "$pkg" '.resultcount > 0 and (.results[]? | select(.Name == $p))' >/dev/null 2>&1 <<<"$response"
}

ensure_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
        return 0
    fi
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
        return 0
    fi

    info "No AUR helper found; bootstrapping paru-bin from the AUR."
    if ! arch_install_official base-devel git; then
        fail "Could not install base-devel/git required to build an AUR helper."
        return 1
    fi

    if ((DRY_RUN == 1)); then
        info "[dry-run] would clone paru-bin and run makepkg -si"
        AUR_HELPER="paru"
        return 0
    fi

    require_sudo
    local tmp
    tmp="$(mktemp_dir)"
    if ! git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"; then
        fail "Could not clone paru-bin from the AUR."
        return 1
    fi
    if ! (cd "$tmp/paru-bin" && makepkg -si --noconfirm); then
        fail "Building/installing paru-bin failed."
        return 1
    fi
    if ! command -v paru >/dev/null 2>&1; then
        fail "paru was not found after bootstrapping."
        return 1
    fi

    AUR_HELPER="paru"
    return 0
}

arch_install_aur() {
    local -a missing=()
    local pkg

    for pkg in "$@"; do
        arch_pkg_installed "$pkg" || missing+=("$pkg")
    done

    if ((${#missing[@]} == 0)); then
        return 0
    fi

    if ! ensure_aur_helper; then
        fail "AUR helper unavailable; cannot install: ${missing[*]}"
        return 1
    fi

    for pkg in "${missing[@]}"; do
        if ! aur_pkg_available "$pkg"; then
            warn "AUR package could not be verified: $pkg"
        fi
    done

    info "Installing AUR packages with $AUR_HELPER: ${missing[*]}"
    if run "$AUR_HELPER" -S --needed --noconfirm "${missing[@]}"; then
        return 0
    fi

    warn "Batch AUR install failed; retrying packages individually."
    local failed=0
    for pkg in "${missing[@]}"; do
        if ! run "$AUR_HELPER" -S --needed --noconfirm "$pkg"; then
            fail "AUR installation failed for: $pkg"
            failed=1
        fi
    done
    return "$failed"
}

install_arch() {
    info "Preparing Arch Linux packages."
    local -a official=() aur=()
    local pkg

    # Every dependency is checked against the official repositories first,
    # including entries that are normally AUR-only.
    for pkg in "${ARCH_OFFICIAL[@]}" "${ARCH_AUR[@]}"; do
        if arch_pkg_installed "$pkg"; then
            continue
        fi
        if arch_pkg_available "$pkg"; then
            official+=("$pkg")
        else
            if [[ " ${ARCH_OFFICIAL[*]} " == *" $pkg "* ]]; then
                warn "$pkg is not in the official repositories; trying AUR."
            fi
            aur+=("$pkg")
        fi
    done

    if ((${#official[@]})); then
        arch_install_official "${official[@]}" || true
    fi

    if ((${#aur[@]})); then
        mapfile -t aur < <(printf '%s\n' "${aur[@]}" | sort -u)
        arch_install_aur "${aur[@]}" || true
    fi
}

# ---------------------------------------------------------------------------
# Fedora Linux
# ---------------------------------------------------------------------------
fedora_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

fedora_pkg_available() {
    local escaped="${1//./\\.}"
    dnf -q list --available "$1" 2>/dev/null | grep -qE "^${escaped}\\."
}

fedora_install_official() {
    local -a missing=() unavailable=()
    local pkg

    for pkg in "$@"; do
        if fedora_pkg_installed "$pkg"; then
            continue
        fi
        if fedora_pkg_available "$pkg"; then
            missing+=("$pkg")
        else
            unavailable+=("$pkg")
        fi
    done

    if ((${#unavailable[@]})); then
        warn "Not available in enabled Fedora repositories: ${unavailable[*]}"
    fi

    if ((${#missing[@]} == 0)); then
        return 0
    fi

    info "Installing Fedora packages: ${missing[*]}"
    if run_sudo dnf install -y "${missing[@]}"; then
        return 0
    fi

    warn "Batch dnf install failed; retrying packages individually."
    local failed=0
    for pkg in "${missing[@]}"; do
        if ! run_sudo dnf install -y "$pkg"; then
            fail "dnf failed to install: $pkg"
            failed=1
        fi
    done
    return "$failed"
}

fedora_enable_copr() {
    local copr="$1"
    if dnf -q repolist --enabled 2>/dev/null | grep -Fq "${copr//\//:}"; then
        return 0
    fi
    info "Enabling COPR repository: $copr"
    run_sudo dnf copr enable -y "$copr"
}

fedora_try_install_copr() {
    local pkg="$1" copr="$2"

    if fedora_pkg_installed "$pkg"; then
        return 0
    fi

    # Priority: package already available in an enabled DNF repository.
    if fedora_pkg_available "$pkg"; then
        run_sudo dnf install -y "$pkg"
        return $?
    fi

    if ! fedora_enable_copr "$copr"; then
        return 1
    fi
    run_sudo dnf install -y "$pkg"
}

fedora_install_copr_pkg() {
    local pkg="$1" copr="$2"
    if ! fedora_try_install_copr "$pkg" "$copr"; then
        fail "Could not install $pkg from COPR $copr."
        return 1
    fi
}

install_vesktop_fedora() {
    if fedora_pkg_installed vesktop || command -v vesktop >/dev/null 2>&1 || [[ -x /opt/Vesktop/vesktop ]]; then
        ok "Vesktop is already installed."
        return 0
    fi

    if ((DRY_RUN == 1)); then
        info "[dry-run] would try COPR dominkus/Vesktop, then the official GitHub RPM."
        return 0
    fi

    # COPR first (priority order: DNF -> other repositories -> COPR).
    if fedora_try_install_copr vesktop dominkus/Vesktop; then
        ok "Vesktop installed from COPR."
        return 0
    fi

    # Upstream fallback: Vesktop publishes an official x86_64 RPM on GitHub.
    info "COPR has no usable build; installing the official upstream Vesktop RPM."
    local api json url digest tmp rpm_file
    if ! api="$(curl -fsSL --max-time 30 https://api.github.com/repos/Vencord/Vesktop/releases/latest 2>/dev/null)"; then
        fail "Could not query the Vesktop GitHub release."
        manual "Install Vesktop manually from https://github.com/Vencord/Vesktop/releases (x86_64 RPM)."
        return 1
    fi

    url="$(jq -r '.assets[] | select(.name | test("x86_64\\.rpm$")) | .browser_download_url' <<<"$api" | head -n1)"
    digest="$(jq -r '.assets[] | select(.name | test("x86_64\\.rpm$")) | .digest' <<<"$api" | head -n1)"
    if [[ -z "$url" || "$url" == "null" ]]; then
        fail "No x86_64 RPM found in the latest Vesktop release."
        manual "Install Vesktop manually from https://github.com/Vencord/Vesktop/releases."
        return 1
    fi

    tmp="$(mktemp_dir)"
    rpm_file="$tmp/vesktop.rpm"
    if ! curl -fL --retry 3 --connect-timeout 15 -o "$rpm_file" "$url"; then
        fail "Could not download the Vesktop RPM."
        manual "Install Vesktop manually from $url"
        return 1
    fi

    if [[ -n "$digest" && "$digest" != "null" ]]; then
        if ! printf '%s  %s\n' "${digest#sha256:}" "$rpm_file" | sha256sum -c - >/dev/null 2>&1; then
            fail "Vesktop RPM checksum verification failed."
            manual "Install Vesktop manually from $url"
            return 1
        fi
    else
        warn "No checksum published for the Vesktop RPM; continuing without verification."
    fi

    if ! run_sudo dnf install -y "$rpm_file"; then
        fail "dnf could not install the Vesktop RPM."
        manual "Install Vesktop manually from $url"
        return 1
    fi
    ok "Vesktop installed from the official upstream RPM."
}

create_spotify_wrapper() {
    local wrapper="$HOME/.local/bin/spotify-launcher"
    if [[ -e "$wrapper" || -L "$wrapper" ]]; then
        return 0
    fi
    info "Creating a spotify-launcher compatibility wrapper for the Fedora Spotify client."
    if ((DRY_RUN == 1)); then
        info "[dry-run] would create $wrapper"
        return 0
    fi
    mkdir -p "$HOME/.local/bin"
    cat >"$wrapper" <<'EOF'
#!/usr/bin/env bash
exec spotify "$@"
EOF
    chmod 755 "$wrapper"
}

install_spotify_fedora() {
    if command -v spotify-launcher >/dev/null 2>&1; then
        ok "spotify-launcher is already installed."
        return 0
    fi
    if command -v spotify >/dev/null 2>&1; then
        create_spotify_wrapper
        return 0
    fi

    if ((DRY_RUN == 1)); then
        info "[dry-run] would try COPR lamoustacheauchocolat/spotify-launcher, then RPM Fusion lpf-spotify-client."
        return 0
    fi

    if fedora_try_install_copr spotify-launcher lamoustacheauchocolat/spotify-launcher; then
        ok "spotify-launcher installed from COPR."
        return 0
    fi

    # RPM Fusion is the relevant Fedora third-party repository for Spotify.
    if dnf -q repolist --enabled 2>/dev/null | grep -qE '^rpmfusion-nonfree([[:space:]]|$)'; then
        if ! fedora_pkg_installed lpf-spotify-client; then
            run_sudo dnf install -y lpf-spotify-client || true
        fi
        manual "Spotify: run 'sudo lpf update spotify-client' and accept the Spotify EULA. Re-run this script afterwards to create the spotify-launcher wrapper."
    else
        manual "Spotify: enable RPM Fusion nonfree and run 'sudo dnf install lpf-spotify-client && sudo lpf update spotify-client', or use the official Spotify Linux download."
    fi
}

install_neofetch_fedora() {
    if command -v neofetch >/dev/null 2>&1; then
        ok "neofetch is already installed."
        return 0
    fi
    if ((DRY_RUN == 1)); then
        info "[dry-run] would install neofetch from the official upstream script."
        return 0
    fi

    # neofetch is not packaged for current Fedora releases.  The project is
    # archived upstream; install its official 7.1.0 script into ~/.local/bin.
    local tmp
    tmp="$(mktemp_dir)"
    if ! curl -fsSL --max-time 30 \
        "https://raw.githubusercontent.com/dylanaraps/neofetch/7.1.0/neofetch" \
        -o "$tmp/neofetch"; then
        fail "Could not download neofetch."
        manual "Install neofetch from https://github.com/dylanaraps/neofetch (7.1.0) or use fastfetch instead."
        return 1
    fi
    if ! printf '%s  %s\n' \
        "3dc33493e54029fb1528251552093a9f9a2894fcf94f9c3a6f809136a42348c7" \
        "$tmp/neofetch" | sha256sum -c - >/dev/null 2>&1; then
        fail "neofetch checksum verification failed."
        manual "Install neofetch from https://github.com/dylanaraps/neofetch (7.1.0)."
        return 1
    fi

    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmp/neofetch" "$HOME/.local/bin/neofetch"
    ok "neofetch installed to ~/.local/bin/neofetch."
}

install_starship_fedora() {
    if command -v starship >/dev/null 2>&1; then
        ok "starship is already installed."
        return 0
    fi

    if ((DRY_RUN == 1)); then
        info "[dry-run] would try COPR atim/starship, then the official starship installer."
        return 0
    fi

    if fedora_try_install_copr starship atim/starship; then
        ok "starship installed from COPR."
        return 0
    fi

    # The atim/starship COPR does not always publish builds for the newest
    # Fedora release.  Fall back to the official upstream installer.
    info "COPR has no usable build; using the official starship installer."
    local tmp
    tmp="$(mktemp_dir)"
    if ! curl -fsSL --max-time 30 https://starship.rs/install.sh -o "$tmp/install.sh"; then
        fail "Could not download the official starship installer."
        manual "Install starship from https://starship.rs/guide/#%F0%9F%9A%80-installation"
        return 1
    fi
    if ! run_sudo sh "$tmp/install.sh" -y; then
        fail "The official starship installer failed."
        manual "Install starship from https://starship.rs/guide/#%F0%9F%9A%80-installation"
        return 1
    fi
    ok "starship installed from the official upstream installer."
}

install_fedora() {
    info "Preparing Fedora packages."
    fedora_install_official "${FEDORA_OFFICIAL[@]}" || true

    local pkg
    for pkg in lazygit app2unit ghostty vicinae helium-bin bibata-cursor-themes yazi; do
        fedora_install_copr_pkg "$pkg" "${FEDORA_COPR[$pkg]}" || true
    done

    install_starship_fedora || true
    install_vesktop_fedora || true
    install_spotify_fedora || true
    install_neofetch_fedora || true
}

# ---------------------------------------------------------------------------
# User-local fallback fonts
# ---------------------------------------------------------------------------
download_file() {
    local url="$1" destination="$2"
    curl -fL --retry 3 --connect-timeout 15 --max-time 600 -o "$destination" "$url"
}

verify_sha256() {
    local file="$1" expected="$2"
    printf '%s  %s\n' "$expected" "$file" | sha256sum -c - >/dev/null 2>&1
}

font_family_present() {
    local family="$1" output
    command -v fc-list >/dev/null 2>&1 || return 1
    if ! output="$(fc-list 2>/dev/null)"; then
        return 1
    fi
    grep -qiE "${family}(,|:)" <<<"$output"
}

install_manual_fonts() {
    if ((INSTALL_FONTS == 0)); then
        return 0
    fi
    if ! command -v fc-cache >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1; then
        warn "fontconfig/unzip are unavailable; skipping user-local font installation."
        return 0
    fi

    local need_nerd=0 need_google_sans=0 need_google_flex=0
    font_family_present "JetBrainsMono Nerd Font" || need_nerd=1
    font_family_present "Google Sans" || need_google_sans=1
    font_family_present "Google Sans Flex" || need_google_flex=1

    if ((DRY_RUN == 1)); then
        if ((need_nerd)); then
            info "[dry-run] would install JetBrainsMono Nerd Font from upstream."
        fi
        if ((need_google_sans)); then
            info "[dry-run] would install Google Sans from upstream."
        fi
        if ((need_google_flex)); then
            info "[dry-run] would install Google Sans Flex from upstream."
        fi
        return 0
    fi

    local tmp dest zip
    tmp="$(mktemp_dir)"

    if ((need_nerd)); then
        info "Installing JetBrainsMono Nerd Font from the official Nerd Fonts release."
        zip="$tmp/JetBrainsMono.zip"
        if download_file \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.zip" \
            "$zip" &&
            verify_sha256 "$zip" "fab782a66f7d3019da64f6572db9fc5d3a4bcb19f9fa13e2d8a62e3693d6396e"; then
            dest="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
            mkdir -p "$dest"
            if unzip -q -o -j "$zip" 'JetBrainsMonoNerdFont-*.ttf' -d "$dest"; then
                ok "JetBrainsMono Nerd Font installed."
            else
                fail "Could not extract JetBrainsMono Nerd Font."
            fi
        else
            fail "Could not download or verify the JetBrainsMono Nerd Font archive."
            manual "Install JetBrainsMono Nerd Font from https://github.com/ryanoasis/nerd-fonts/releases."
        fi
    fi

    if ((need_google_sans)); then
        info "Installing Google Sans from the official Google Fonts release."
        zip="$tmp/GoogleSans.zip"
        if download_file \
            "https://github.com/googlefonts/googlesans/releases/download/v14.000/GoogleSans-v14.000.zip" \
            "$zip" &&
            verify_sha256 "$zip" "d338f0e74f5eabead86a85b87edf4cc50cd6561196dbe173d1db4139e95b3ca7"; then
            dest="$HOME/.local/share/fonts/GoogleSans"
            mkdir -p "$dest"
            if unzip -q -o -j "$zip" 'build/GoogleSans/static/*.ttf' -d "$dest"; then
                ok "Google Sans installed."
            else
                fail "Could not extract Google Sans."
            fi
        else
            fail "Could not download or verify the Google Sans archive."
            manual "Install Google Sans from https://github.com/googlefonts/googlesans/releases."
        fi
    fi

    if ((need_google_flex)); then
        info "Installing Google Sans Flex from the official Google Fonts release."
        zip="$tmp/GoogleSansFlex.zip"
        if download_file \
            "https://github.com/googlefonts/googlesans-flex/releases/download/v5.000/GoogleSansFlex-v5.000.zip" \
            "$zip" &&
            verify_sha256 "$zip" "c20b00878dd801d1bfc06d771732447940c7255bf94cf538ce0102c7fb06fa85"; then
            dest="$HOME/.local/share/fonts/GoogleSansFlex"
            mkdir -p "$dest"
            if unzip -q -o -j "$zip" '*.ttf' -d "$dest"; then
                ok "Google Sans Flex installed."
            else
                fail "Could not extract Google Sans Flex."
            fi
        else
            fail "Could not download or verify the Google Sans Flex archive."
            manual "Install Google Sans Flex from https://github.com/googlefonts/googlesans-flex/releases."
        fi
    fi

    fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# Cross-distribution compatibility shims
# ---------------------------------------------------------------------------
create_vesktop_shim() {
    if [[ ! -e /opt/Vesktop/vesktop ]] && command -v vesktop >/dev/null 2>&1; then
        info "Creating /opt/Vesktop/vesktop compatibility link for the configured keybind."
        run_sudo install -d /opt/Vesktop
        run_sudo ln -sfn "$(command -v vesktop)" /opt/Vesktop/vesktop
    fi
}

create_compat_shims() {
    case "$DISTRO" in
        arch)
            if command -v helium-browser >/dev/null 2>&1 && ! command -v helium >/dev/null 2>&1 &&
                [[ ! -e /usr/local/bin/helium && ! -L /usr/local/bin/helium ]]; then
                info "Creating /usr/local/bin/helium -> /usr/bin/helium-browser compatibility link."
                run_sudo install -d /usr/local/bin
                run_sudo ln -sfn /usr/bin/helium-browser /usr/local/bin/helium
            fi
            create_vesktop_shim
            ;;
        fedora)
            # Spotify is handled in install_spotify_fedora, including the
            # compatibility wrapper for RPM Fusion's spotify-client.
            create_vesktop_shim
            ;;
    esac
}

# ---------------------------------------------------------------------------
# GNU Stow
# ---------------------------------------------------------------------------
ensure_stow() {
    if command -v stow >/dev/null 2>&1; then
        return 0
    fi
    warn "GNU Stow is not installed; installing it."
    case "$DISTRO" in
        arch) arch_install_official stow || true ;;
        fedora) fedora_install_official stow || true ;;
    esac
    if ! command -v stow >/dev/null 2>&1; then
        fail "GNU Stow is still unavailable."
        return 1
    fi
}

cleanup_removed_links() {
    local pkg path link target
    for pkg in "${REMOVED_PACKAGES[@]}"; do
        path="$HOME/.config/$pkg"
        if [[ -L "$path" ]]; then
            target="$(realpath -m -- "$path" 2>/dev/null || true)"
            if [[ "$target" == "$REPO_DIR/$pkg/"* ]]; then
                if ((DRY_RUN == 1)); then
                    info "[dry-run] would remove stale symlink from removed package: $path"
                else
                    info "Removing stale symlink from removed package: $path"
                    rm -f -- "$path"
                fi
            fi
        elif [[ -d "$path" ]]; then
            while IFS= read -r -d '' link; do
                target="$(realpath -m -- "$link" 2>/dev/null || true)"
                if [[ "$target" == "$REPO_DIR/$pkg/"* ]]; then
                    if ((DRY_RUN == 1)); then
                        info "[dry-run] would remove stale symlink from removed package: $link"
                    else
                        info "Removing stale symlink from removed package: $link"
                        rm -f -- "$link"
                    fi
                fi
            done < <(find "$path" -type l -print0 2>/dev/null)
        fi
    done
}

run_stow() {
    if ! ensure_stow; then
        return 1
    fi

    info "Checking for Stow conflicts (simulation, no changes)."
    local simulate_output
    if ! simulate_output="$(
        stow --dir="$REPO_DIR" --target="$HOME" --simulate --restow "${STOW_PACKAGES[@]}" 2>&1
    )"; then
        error "Stow found conflicts. No links were changed."
        printf '%s\n' "$simulate_output" >&2
        fail "Stow conflicts must be resolved before the dotfiles can be linked."
        return 1
    fi

    info "Linking ${#STOW_PACKAGES[@]} Stow packages into $HOME."
    if ! run stow --dir="$REPO_DIR" --target="$HOME" --restow --verbose=1 "${STOW_PACKAGES[@]}"; then
        fail "Stow failed while creating links."
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Verification / report
# ---------------------------------------------------------------------------
verify_stow_links() {
    local path
    for path in \
        "$HOME/.config/niri" \
        "$HOME/.config/mpv" \
        "$HOME/.config/fish" \
        "$HOME/.local/scripts" \
        "$HOME/.themes"; do
        if [[ ! -e "$path" && ! -L "$path" ]]; then
            fail "Expected Stow target is missing: $path"
        fi
    done

    for path in \
        "$HOME/.config/mpv/scripts/material-osc.lua" \
        "$HOME/.config/mpv/scripts/thumbfast.lua" \
        "$HOME/.config/mpv/script-opts/material-osc.conf" \
        "$HOME/.config/mpv/fonts/material-osc_icons.otf" \
        "$HOME/.config/mpv/fonts/material-osc_google_sans_flex.ttf"; do
        [[ -e "$path" ]] || fail "Expected MPV OSC file is missing: $path"
    done
}

verify_installation() {
    local -a missing=()
    local cmd

    for cmd in \
        stow fish niri noctalia dms ghostty foot starship zoxide fzf eza yazi \
        tmux nvim btop lazygit fastfetch bat fd rg wl-copy wtype fuzzel \
        mpv ffmpeg yt-dlp playerctl pamixer brightnessctl wf-recorder grim slurp \
        jq curl unzip fc-cache app2unit vicinae; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done

    if ! command -v helium >/dev/null 2>&1 && ! command -v helium-browser >/dev/null 2>&1; then
        missing+=("helium/helium-browser")
    fi
    if ! command -v vesktop >/dev/null 2>&1 && [[ ! -x /opt/Vesktop/vesktop ]]; then
        warn "Vesktop was not found (the Mod+D keybind expects /opt/Vesktop/vesktop)."
    fi
    if ! command -v spotify-launcher >/dev/null 2>&1 && ! command -v spotify >/dev/null 2>&1; then
        warn "Spotify was not installed; the Mod+M keybind expects spotify-launcher."
    fi
    if ! command -v neofetch >/dev/null 2>&1; then
        warn "neofetch was not installed; the 'clr' alias falls back to it. fastfetch is available."
    fi

    for cmd in "${missing[@]}"; do
        fail "Required command not found: $cmd"
    done

    for cmd in wpctl nmcli bluetoothctl notify-send; do
        command -v "$cmd" >/dev/null 2>&1 || warn "Optional desktop command not found: $cmd"
    done

    if command -v fc-list >/dev/null 2>&1; then
        font_family_present "JetBrainsMono Nerd Font" || warn "JetBrainsMono Nerd Font was not detected by fontconfig."
        font_family_present "Google Sans" || warn "Google Sans was not detected by fontconfig."
        font_family_present "Google Sans Flex" || warn "Google Sans Flex was not detected by fontconfig."
    fi
}

print_unique() {
    awk '!seen[$0]++'
}

print_summary() {
    printf '\n'
    if ((${#WARNINGS[@]})); then
        info "Warnings"
        printf '%s\n' "${WARNINGS[@]}" | print_unique | sed 's/^/  - /'
    fi
    if ((${#MANUAL_STEPS[@]})); then
        info "Manual steps"
        printf '%s\n' "${MANUAL_STEPS[@]}" | print_unique | sed 's/^/  - /'
    fi
    if ((${#FAILURES[@]})); then
        error "The following steps failed:"
        printf '%s\n' "${FAILURES[@]}" | print_unique | sed 's/^/  - /' >&2
        printf '\n'
        error "Installation finished with errors."
        exit 1
    fi
    ok "Installation complete."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"
    detect_distro

    if ((EUID == 0 && DRY_RUN == 0)); then
        error "Do not run this script as root. Run it as your normal user; sudo is used when needed."
        exit 1
    fi

    info "Repository: $REPO_DIR"
    info "Distribution: $DISTRO_NAME ($DISTRO)"
    if ((DRY_RUN == 1)); then
        info "Dry-run mode: no system changes will be made."
    fi

    if ((DO_PACKAGES == 1)); then
        case "$DISTRO" in
            arch) install_arch ;;
            fedora) install_fedora ;;
        esac
        install_manual_fonts
        create_compat_shims
    fi

    if ((DO_STOW == 1)); then
        cleanup_removed_links
        run_stow || true
    fi

    if ((DRY_RUN == 0)); then
        if ((DO_PACKAGES == 1)); then
            verify_installation
        fi
        if ((DO_STOW == 1)); then
            verify_stow_links
        fi
    fi
    print_summary
}

main "$@"