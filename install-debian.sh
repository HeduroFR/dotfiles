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
NVM_DIR="$HOME/.nvm"

# Fonctions d'affichage
print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║   Dotfiles Installation Script (Debian)  ║"
    echo "╚══════════════════════════════════════════╝"
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

# Vérifier si on est sur Debian
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "debian" ]]; then
            print_warning "Ce script est optimisé pour Debian 12/13"
            read -p "Continuer quand même ? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            print_success "Debian $VERSION_ID détecté"
        fi
    else
        print_error "Impossible de détecter l'OS"
        exit 1
    fi
}

# Activer les backports Debian (pour avoir des versions plus récentes)
enable_backports() {
    print_info "Activation des backports Debian..."
    
    DEBIAN_VERSION=$(lsb_release -sc)
    BACKPORTS_LINE="deb http://deb.debian.org/debian ${DEBIAN_VERSION}-backports main contrib non-free non-free-firmware"
    
    if ! grep -q "${DEBIAN_VERSION}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "$BACKPORTS_LINE" | sudo tee /etc/apt/sources.list.d/backports.list
        sudo apt update
        print_success "Backports activés"
    else
        print_success "Backports déjà activés"
    fi
}

# Backup des configs existantes
backup_existing_configs() {
    print_info "Création d'un backup de tes configs existantes..."
    
    mkdir -p "$BACKUP_DIR"
    
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
    sudo apt install -y git curl wget build-essential \
        software-properties-common gnupg2 ca-certificates \
        lsb-release apt-transport-https
    
    # Terminal & Shell
    print_info "Installation de zsh, tmux..."
    sudo apt install -y zsh tmux
    
    # Kitty (installation via binary officiel car pas dans Debian stable)
    install_kitty
    
    # Neovim (via AppImage - plus simple et à jour sur Debian)
    install_neovim_appimage
    
    # Node.js via nvm (recommandé pour Debian)
    install_nodejs_nvm
    
    # Bun
    print_info "Installation de Bun..."
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
        print_success "Bun installé"
    else
        print_success "Bun déjà installé"
    fi
    
    # CLI tools
    print_info "Installation des outils CLI..."
    
    # Ripgrep, fd-find, fzf sont dans les repos Debian
    sudo apt install -y ripgrep fd-find fzf htop
    
    # bat et exa peuvent nécessiter les backports ou compilation
    install_modern_cli_tools
    
    # Créer les symlinks pour fd (Debian l'appelle fdfind)
    if [ ! -L ~/.local/bin/fd ]; then
        mkdir -p ~/.local/bin
        ln -sf $(which fdfind) ~/.local/bin/fd 2>/dev/null
        print_success "Symlink fd créé"
    fi
    
    print_success "Dépendances système installées"
}

# Installer Kitty (binary officiel)
install_kitty() {
    print_info "Installation de Kitty..."
    
    if ! command -v kitty &> /dev/null; then
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
        
        # Créer les symlinks
        mkdir -p ~/.local/bin
        ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/
        
        # Créer le desktop entry
        mkdir -p ~/.local/share/applications
        cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
        cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
        
        # Mettre à jour les icônes
        sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty*.desktop
        
        print_success "Kitty installé"
    else
        print_success "Kitty déjà installé"
    fi
}

# Installer Neovim via AppImage
install_neovim_appimage() {
    print_info "Installation de Neovim (AppImage)..."
    
    if ! command -v nvim &> /dev/null || [[ "$(nvim --version | head -n1)" != *"0.10"* ]]; then
        mkdir -p ~/.local/bin
        
        # Télécharger la dernière version stable
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
        chmod +x nvim.appimage
        mv nvim.appimage ~/.local/bin/nvim
        
        print_success "Neovim installé (AppImage)"
    else
        print_success "Neovim déjà installé"
    fi
}

# Installer Node.js via nvm (méthode recommandée pour Debian)
install_nodejs_nvm() {
    print_info "Installation de Node.js via nvm..."
    
    if [ ! -d "$NVM_DIR" ]; then
        # Installer nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        
        # Charger nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Installer Node.js LTS
        nvm install --lts
        nvm use --lts
        
        print_success "Node.js installé via nvm"
    else
        print_success "nvm déjà installé"
        # Charger nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if ! command -v node &> /dev/null; then
            nvm install --lts
            nvm use --lts
        fi
    fi
}

# Installer bat et exa (outils CLI modernes)
install_modern_cli_tools() {
    print_info "Installation de bat et exa..."
    
    # Essayer d'installer bat depuis les backports
    if ! command -v bat &> /dev/null && ! command -v batcat &> /dev/null; then
        sudo apt install -y -t $(lsb_release -sc)-backports bat 2>/dev/null || {
            # Si backports ne fonctionne pas, télécharger le .deb
            print_info "Installation de bat depuis GitHub..."
            cd /tmp
            wget https://github.com/sharkdp/bat/releases/download/v0.24.0/bat_0.24.0_amd64.deb
            sudo dpkg -i bat_0.24.0_amd64.deb
            rm bat_0.24.0_amd64.deb
        }
        
        # Créer symlink si nécessaire (Debian l'appelle batcat)
        if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
            mkdir -p ~/.local/bin
            ln -sf $(which batcat) ~/.local/bin/bat
        fi
    fi
    
    # Installer exa (ou eza, le fork maintenu)
    if ! command -v exa &> /dev/null && ! command -v eza &> /dev/null; then
        print_info "Installation de eza (fork d'exa)..."
        cd /tmp
        wget https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz
        tar -xzf eza_x86_64-unknown-linux-gnu.tar.gz
        mkdir -p ~/.local/bin
        mv eza ~/.local/bin/
        rm eza_x86_64-unknown-linux-gnu.tar.gz
        
        # Créer un alias exa -> eza pour compatibilité
        ln -sf ~/.local/bin/eza ~/.local/bin/exa
    fi
    
    print_success "Outils CLI modernes installés"
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
    
    if [ -d "$DOTFILES_DIR" ]; then
        print_warning "Repo bare existant trouvé, suppression..."
        rm -rf "$DOTFILES_DIR"
    fi
    
    git clone --bare "$DOTFILES_REPO" "$DOTFILES_DIR"
    
    function config {
        /usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
    }
    
    config checkout -f 2>&1
    
    if [ $? = 0 ]; then
        print_success "Dotfiles installés"
    else
        print_error "Conflit lors du checkout"
        print_info "Backup et retry..."
        config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} "$BACKUP_DIR/{}"
        config checkout -f
    fi
    
    config config --local status.showUntrackedFiles no
    
    if ! grep -q "alias config=" "$HOME/.zshrc" 2>/dev/null; then
        echo "alias config='/usr/bin/git --git-dir=\$HOME/.dotfiles/ --work-tree=\$HOME'" >> "$HOME/.zshrc"
    fi
    
    print_success "Alias 'config' configuré"
}

# Installer les plugins Neovim
install_nvim_plugins() {
    print_info "Installation des plugins Neovim..."
    
    # Charger nvm si nécessaire pour les LSP
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
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

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# Exemples de secrets :
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

# Configurer le PATH
setup_path() {
    print_info "Configuration du PATH..."
    
    # Ajouter .local/bin au PATH si pas déjà présent
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
    
    print_success "PATH configuré"
}

# Menu principal
show_menu() {
    clear
    print_header
    echo ""
    echo "Que veux-tu installer ?"
    echo ""
    echo "  1) Installation complète (recommandé)"
    echo "     → Backports + Dépendances + Configs + Plugins"
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
    enable_backports
    backup_existing_configs
    install_dependencies
    install_nerd_font
    install_dotfiles_bare
    setup_path
    create_local_files
    install_nvim_plugins
    setup_zsh
    
    print_success "Installation terminée ! 🎉"
    print_warning "Redémarre ton terminal ou lance: source ~/.zshrc"
    print_info "Backup disponible dans: $BACKUP_DIR"
    echo ""
    print_info "Note: Si nvim ou kitty ne fonctionnent pas, assure-toi que ~/.local/bin est dans ton PATH"
}

# Dépendances seulement
dependencies_only() {
    clear
    print_header
    print_info "Installation des dépendances..."
    echo ""
    
    check_os
    enable_backports
    install_dependencies
    install_nerd_font
    setup_path
    
    print_success "Dépendances installées ! 🎉"
    print_warning "Redémarre ton terminal pour appliquer les changements"
}

# Configs seulement
configs_only() {
    clear
    print_header
    print_info "Installation des configs..."
    echo ""
    
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
    
    # Backports
    read -p "Activer les backports Debian ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        enable_backports
    fi
    
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
        setup_path
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
        echo ""
        echo "Note: Ce script est optimisé pour Debian 12 (Bookworm) et 13 (Trixie)"
        exit 0
    fi
    
    if [ "$1" = "--full" ]; then
        full_install
        exit 0
    fi
    
    if [ "$1" = "--deps" ]; then
        dependencies_only
        exit 0
    fi
    
    if [ "$1" = "--configs" ]; then
        configs_only
        exit 0
    fi
    
    show_menu
}

# Lancer le script
main "$@"
