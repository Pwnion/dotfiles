# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

# Ensure zinit intialises correctly
zinit cdreplay -q

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias test="python manage.py test --keepdb -k"
alias testp="python manage.py test --keepdb --parallel -k"
alias mr="mise run"
alias asl="aws sso login"
alias m="python manage.py"
alias dj="python manage.py runserver"
alias dr="python manage.py rundramatiq"
alias sink="python manage.py sync_frontend"
alias sp="python manage.py shell_plus"
alias fe="mise watch build:frontend:dev --clear"
alias cdw="cd ~/dev/workforce"
alias cdu="cd ~/dev/uptick-cluster"
alias dbreset="dropdb workforce; createdb workforce && psql --username=$USER workforce < $1"
alias pull="jj git fetch && jj rebase -d develop@origin"

# Shell integrations
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(direnv hook zsh)"
eval "$(fzf --zsh)"
eval "$(mise activate zsh)"
eval "$(zoxide init --cmd cd zsh)"
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/ohmyposh.toml)"
fi
source <(COMPLETE=zsh jj)

# Path Exports
export PATH=/Users/pwnion/dev/workforce/.venv/bin:$PATH
export PATH=/Users/pwnion/.local/share/mise/installs:$PATH
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/Users/$USERNAME/.bun/bin:$PATH:~/.local/bin

# Other Exports
export GITOPS_APPS_DIRECTORY=~/dev/uptick-cluster/apps

# Functions
nuke() {
  if [ -n "$1" ]; then
    target="$1"
  else
    target="$(history | grep 'inv dbreset' | grep -v 'history' | tail -n 1 | grep -oE '([^ =]+)$')"
    if [[ -z "$target" ]]; then
      echo "Error: Could not retrieve dump file from history. Please provide a dump file instead."
      return 1
    fi
  fi

  echo "Destroying workforce and restoring \"$target\" ..."
  read -q "REPLY?Do you want to proceed? (y/N) "
  echo
  if [[ "$REPLY" =~ ^[yY]$ ]]; then
    inv docker.nuke
    mise run clean
    uv clean
    rm -rf .node_modules .venv .mypy_cache
    mise run build
    inv dbreset -d "$target"
    docker start dev-db-1
  fi
}

cs() {
    local selected_server
    selected_server=$(find $GITOPS_APPS_DIRECTORY -type d | xargs basename | fzf +m --height 50%)
    if [[ -n "$selected_server" ]]; then
        echo "$selected_server"
    fi
}

ks() {
    server=$(cs)
    cluster=$(gitops summary | grep -w "$server " | grep -E -o "prod-[a-z]+-\d+ ")
    kubectx "$cluster"
    kubens workforce
    kgp | grep "$server"
}

browse() {
  open "https://$(cs).onuptick.com"
}
