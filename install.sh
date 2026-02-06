#!/bin/bash

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DOTFILES_REPO="https://github.com/HeduroFR/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# Fonctions d'affichage
print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║       Dotfiles Installation Script       ║"
    echo "╔══════════════════════════════════════════╗"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Vérifier si on est sur Ubuntu/Pop!_OS
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" && "$ID" != "pop" ]]; then
            print_warning "Ce script est optimisé pour Ubuntu/Pop!_OS"
            read -p "Continuer quand même ? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
}

# Backup des configs existantes
backup_existing_configs() {
    print_info "Création d'un backup de tes configs existantes..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Liste des configs à backup
    configs=(
        ".config/nvim"
        ".config/kitty"
        ".config/tmux"
        ".tmux.conf"
        ".zshrc"
        ".gitconfig"
    )
    
    for config in "${configs[@]}"; do
        if [ -e "$HOME/$config" ]; then
            cp -r "$HOME/$config" "$BACKUP_DIR/" 2>/dev/null
            print_success "Backup: $config"
        fi
    done
    
    print_success "Backup créé dans: $BACKUP_DIR"
}

# Installer les dépendances système
install_dependencies() {
    print_info "Installation des dépendances système..."
    
    # Update
    sudo apt update
    
    # Essentiels
    print_info "Installation des outils essentiels..."
    sudo apt install -y git curl wget build-essential software-properties-common
    
    # Terminal & Shell
    print_info "Installation de zsh, tmux, kitty..."
    sudo apt install -y zsh tmux kitty
    
    # Neovim (dernière version)
    print_info "Installation de Neovim..."
    if ! command -v nvim &> /dev/null; then
        sudo add-apt-repository ppa:neovim-ppa/unstable -y
        sudo apt update
        sudo apt install -y neovim
    else
        print_success "Neovim déjà installé"
    fi
    
    # Node.js (pour les LSP)
    print_info "Installation de Node.js..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
    else
        print_success "Node.js déjà installé"
    fi
    
    # Bun (optionnel, pour toi qui l'utilises)
    print_info "Installation de Bun..."
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
    else
        print_success "Bun déjà installé"
    fi
    
    # CLI tools
    print_info "Installation des outils CLI..."
    sudo apt install -y ripgrep fd-find fzf bat exa htop
    
    # Créer les symlinks pour fd et bat (noms différents sur Ubuntu)
    if [ ! -L ~/.local/bin/fd ]; then
        mkdir -p ~/.local/bin
        ln -s $(which fdfind) ~/.local/bin/fd 2>/dev/null
    fi
    
    if [ ! -L ~/.local/bin/bat ]; then
        mkdir -p ~/.local/bin
        ln -s $(which batcat) ~/.local/bin/bat 2>/dev/null
    fi
    
    print_success "Dépendances système installées"
}

# Installer Nerd Font
install_nerd_font() {
    print_info "Installation de JetBrainsMono Nerd Font..."
    
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
        cd /tmp
        wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
        unzip -o JetBrainsMono.zip -d "$FONT_DIR"
        rm JetBrainsMono.zip
        fc-cache -fv
        print_success "JetBrainsMono Nerd Font installée"
    else
        print_success "JetBrainsMono Nerd Font déjà installée"
    fi
}

# Cloner et installer les dotfiles (méthode Git Bare)
install_dotfiles_bare() {
    print_info "Installation des dotfiles (méthode Git Bare)..."
    
    # Supprimer l'ancien repo bare si existant
    if [ -d "$DOTFILES_DIR" ]; then
        print_warning "Repo bare existant trouvé, suppression..."
        rm -rf "$DOTFILES_DIR"
    fi
    
    # Cloner le repo bare
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
    
    # Définir la fonction config
    function config {
        /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
    }
    
    # Checkout (forcer si nécessaire)
    config checkout -f 2>&1
    
    if [ $? = 0 ]; then
        print_success "Dotfiles installés"
    else
        print_error "Conflit lors du checkout"
        print_info "Backup et retry..."
        config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} "$BACKUP_DIR/{}"
        config checkout -f
    fi
    
    # Configuration du repo
    config config --local status.showUntrackedFiles no
    
    # Ajouter l'alias dans zshrc
    if ! grep -q "alias config=" "$HOME/.zshrc" 2>/dev/null; then
        echo "alias config='/usr/bin/git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> "$HOME/.zshrc"
    fi
    
    print_success "Alias 'config' configuré"
}

# Installer les plugins Neovim
install_nvim_plugins() {
    print_info "Installation des plugins Neovim..."
    
    # Lazy.nvim devrait s'installer automatiquement au premier lancement
    # Mais on peut forcer l'installation
    nvim --headless "+Lazy! sync" +qa 2>/dev/null
    
    print_success "Plugins Neovim installés"
}

# Configurer zsh comme shell par défaut
setup_zsh() {
    print_info "Configuration de zsh comme shell par défaut..."
    
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s $(which zsh)
        print_success "zsh configuré (reconnecte-toi pour appliquer)"
    else
        print_success "zsh déjà configuré"
    fi
}

# Créer le fichier .zshrc.local pour les secrets
create_local_files() {
    print_info "Création des fichiers locaux pour les secrets..."
    
    if [ ! -f "$HOME/.zshrc.local" ]; then
        cat > "$HOME/.zshrc.local" << 'EOF'
# ~/.zshrc.local
# Ce fichier n'est PAS versionné - mets tes secrets ici

# Exemples :
# export GITHUB_TOKEN="ton_token"
# export OPENAI_API_KEY="ta_clé"
# export CUSTOM_VAR="valeur"
EOF
        print_success "Fichier ~/.zshrc.local créé"
        print_warning "N'oublie pas d'ajouter tes secrets dans ~/.zshrc.local"
    else
        print_success "~/.zshrc.local existe déjà"
    fi
}

# Menu principal
show_menu() {
    clear
    print_header
    echo ""
    echo "Que veux-tu installer ?"
    echo ""
    echo "  1) Installation complète (recommandé)"
    echo "     → Dépendances + Configs + Plugins"
    echo ""
    echo "  2) Seulement les dépendances"
    echo "     → Packages système + Fonts + Tools"
    echo ""
    echo "  3) Seulement les configs"
    echo "     → Dotfiles uniquement (nécessite Git)"
    echo ""
    echo "  4) Installation personnalisée"
    echo "     → Choisis étape par étape"
    echo ""
    echo "  5) Quitter"
    echo ""
    read -p "Choix [1-5]: " choice
    
    case $choice in
        1)
            full_install
            ;;
        2)
            dependencies_only
            ;;
        3)
            configs_only
            ;;
        4)
            custom_install
            ;;
        5)
            print_info "Bye!"
            exit 0
            ;;
        *)
            print_error "Choix invalide"
            sleep 2
            show_menu
            ;;
    esac
}

# Installation complète
full_install() {
    clear
    print_header
    print_info "Installation complète démarrée..."
    echo ""
    
    check_os
    backup_existing_configs
    install_dependencies
    install_nerd_font
    install_dotfiles_bare
    create_local_files
    install_nvim_plugins
    setup_zsh
    
    print_success "Installation terminée ! 🎉"
    print_warning "Redémarre ton terminal ou lance: source ~/.zshrc"
    print_info "Backup disponible dans: $BACKUP_DIR"
}

# Dépendances seulement
dependencies_only() {
    clear
    print_header
    print_info "Installation des dépendances..."
    echo ""
    
    check_os
    install_dependencies
    install_nerd_font
    
    print_success "Dépendances installées ! 🎉"
}

# Configs seulement
configs_only() {
    clear
    print_header
    print_info "Installation des configs..."
    echo ""
    
    # Vérifier que Git est installé
    if ! command -v git &> /dev/null; then
        print_error "Git n'est pas installé"
        print_info "Installe d'abord les dépendances (option 2)"
        read -p "Appuie sur Enter pour continuer..."
        show_menu
        return
    fi
    
    backup_existing_configs
    install_dotfiles_bare
    create_local_files
    
    print_success "Configs installées ! 🎉"
    print_warning "Lance: source ~/.zshrc"
    print_info "Backup disponible dans: $BACKUP_DIR"
}

# Installation personnalisée
custom_install() {
    clear
    print_header
    print_info "Installation personnalisée"
    echo ""
    
    # Backup
    read -p "Créer un backup des configs existantes ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_existing_configs
    fi
    
    # Dépendances système
    read -p "Installer les dépendances système ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_dependencies
    fi
    
    # Nerd Font
    read -p "Installer JetBrainsMono Nerd Font ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_nerd_font
    fi
    
    # Dotfiles
    read -p "Installer les dotfiles ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_dotfiles_bare
        create_local_files
    fi
    
    # Plugins Neovim
    read -p "Installer les plugins Neovim ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_nvim_plugins
    fi
    
    # Zsh
    read -p "Configurer zsh comme shell par défaut ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_zsh
    fi
    
    print_success "Installation personnalisée terminée ! 🎉"
    print_warning "Redémarre ton terminal ou lance: source ~/.zshrc"
}

# Main
main() {
    # Si argument --help
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        print_header
        echo "Usage: ./install.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --full          Installation complète"
        echo "  --deps          Dépendances seulement"
        echo "  --configs       Configs seulement"
        echo "  --help, -h      Afficher cette aide"
        echo ""
        echo "Sans option: menu interactif"
        exit 0
    fi
    
    # Si argument --full
    if [ "$1" = "--full" ]; then
        full_install
        exit 0
    fi
    
    # Si argument --deps
    if [ "$1" = "--deps" ]; then
        dependencies_only
        exit 0
    fi
    
    # Si argument --configs
    if [ "$1" = "--configs" ]; then
        configs_only
        exit 0
    fi
    
    # Sinon, menu interactif
    show_menu
}

# Lancer le script
main "$@"
