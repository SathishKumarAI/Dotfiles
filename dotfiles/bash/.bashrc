# ============================================
# Conda Configuration
# ============================================
if [ -f ~/anaconda3/etc/profile.d/conda.sh ]; then
    source ~/anaconda3/etc/profile.d/conda.sh
    conda activate dice_outreach
elif [ -f ~/miniconda3/etc/profile.d/conda.sh ]; then
    source ~/miniconda3/etc/profile.d/conda.sh
    conda activate base
fi



# ============================================
# Starship Prompt (Modern, Fast Prompt)
# ============================================
# if command -v starship &> /dev/null; then
#     eval "$(starship init bash)"
# fi

export STARSHIP_EXE="/c/Program Files/starship/bin/starship"
eval "$("$STARSHIP_EXE" init bash)"

# ============================================
# zoxide (Smart Directory Navigation)
# ============================================
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash)"
    # Aliases for easier navigation
    alias zi="z -i"  # Interactive selection
    alias zz="z -"   # Go back to previous directory
fi

# ============================================
# fzf (Fuzzy File Finder)
# ============================================
if command -v fzf &> /dev/null; then
    # Setup fzf key bindings and fuzzy completion
    source <(fzf --bash 2>/dev/null || echo "")
    
    # Use fd for faster file searching (if available)
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    else
        export FZF_DEFAULT_COMMAND='find . -type f 2>/dev/null'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
    
    # fzf aliases for quick access
    alias f='fzf'                           # Quick file search
    alias ff='fzf --preview "bat --color=always {}"'  # File search with preview
    alias fcd='cd $(find . -type d 2>/dev/null | fzf)'  # Fuzzy cd
    alias fkill='kill -9 $(ps aux | fzf | awk "{print \$2}")'  # Fuzzy process kill
    
    # Enhanced history search with fzf
    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
fi

# ============================================
# Zellij Integration
# ============================================
if command -v zellij &> /dev/null; then
    # Auto-attach to existing session or create new one
    if [ -z "$ZELLIJ" ]; then
        if zellij list-sessions 2>/dev/null | grep -q .; then
            # Attach to existing session if available
            alias zj='zellij attach -c'
        else
            # Create new session
            alias zj='zellij'
        fi
    fi
fi

# ============================================
# Enhanced Navigation Aliases
# ============================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# ============================================
# Git Aliases (if using Git)
# ============================================
if command -v git &> /dev/null; then
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git log --oneline --graph --decorate'
    alias gd='git diff'
fi

# ============================================
# Quality of Life Improvements
# ============================================
# Color support for ls
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# History improvements
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Better directory navigation
shopt -s autocd  # Type directory name to cd into it
shopt -s cdspell  # Auto-correct typos in directory names

# ============================================
# Custom Functions
# ============================================

# Quick directory creation and navigation
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Find files by name
ffind() {
    find . -type f -iname "*$1*" 2>/dev/null
}

# Quick grep with context
grepc() {
    grep -r --color=always -n "$1" . | less -R
}

# ============================================
# Welcome Message (Optional)
# ============================================
# if [ -z "$ZELLIJ" ]; then
#     echo "🚀 Terminal ready! Tools available:"
#     command -v zoxide &> /dev/null && echo "  ✓ zoxide (use 'z <dir>' to jump)"
#     command -v fzf &> /dev/null && echo "  ✓ fzf (use 'f' or Ctrl+T for search)"
#     command -v starship &> /dev/null && echo "  ✓ starship (modern prompt)"
#     command -v zellij &> /dev/null && echo "  ✓ zellij (use 'zj' to launch)"
# fi

# eval "$(oh-my-posh init bash --config "$POSH_THEMES_PATH/jandedobbeleer.omp.json")"

