# Dotfiles

Mes configurations pour un environnement de dev optimal sur Pop!_OS/Ubuntu.

## 🚀 Quick Install
Pop!_OS:
```bash
bash <(curl -s https://raw.githubusercontent.com/HeduroFR/dotfiles/main/install.sh) --full
```

Debian/Ubuntu:
```bash
bash <(curl -s https://raw.githubusercontent.com/HeduroFR/dotfiles/main/install-debian.sh) --full
```

## 📦 Stack

- **OS:** Pop!_OS / Ubuntu
- **Shell:** zsh
- **Terminal:** Kitty
- **Multiplexer:** Tmux  
- **Editor:** Neovim
- **Font:** JetBrainsMono Nerd Font
- **Runtime:** Bun, Node.js

## 🎯 Installation Options

### Menu interactif
```bash
bash <(curl -s https://raw.githubusercontent.com/HeduroFR/dotfiles/main/install.sh)
```

### Installation complète
```bash
./install.sh --full
```

### Seulement les dépendances
```bash
./install.sh --deps
```

### Seulement les configs
```bash
./install.sh --configs
```

## 📝 Post-Installation

1. Redémarre ton terminal
2. Edite `~/.zshrc.local` pour ajouter tes secrets
3. Lance `nvim` pour finaliser l'installation des plugins

## 🔧 Gestion des dotfiles
```bash
# Voir le status
config status

# Ajouter un fichier
config add ~/.config/nvim/init.lua

# Commit
config commit -m "Update nvim config"

# Push
config push
```

## 📂 Structure
```
~/.config/
├── nvim/       # Neovim config
├── kitty/      # Kitty terminal config
└── tmux/       # Tmux config
~/.zshrc        # Zsh configuration
~/.tmux.conf    # Tmux configuration
```

## 🔒 Secrets

Les secrets vont dans `~/.zshrc.local` (non versionné).

## 🐛 Problèmes ?

Ton backup est ici : `~/.config-backup-TIMESTAMP/`
