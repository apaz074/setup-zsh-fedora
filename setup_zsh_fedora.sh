#!/usr/bin/env bash

# Script to configure a powerful Zsh environment on Fedora 42
# Expert Software Engineer in DevOps (with focus on Podman and Toolbox)

set -e # Exit immediately if a command fails
set -u # Treat undefined variables as an error
# set -o pipefail # The return value of a pipeline is the value of the last command to fail (optional)

# --- Configuration Variables ---
JETBRAINS_MONO_NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" # Verify latest version
FONT_INSTALL_DIR="/usr/local/share/fonts/JetBrainsMonoNerdFont"
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
ZSH_CUSTOM_PLUGINS_DIR="${OH_MY_ZSH_DIR}/custom/plugins"

# Oh My Zsh Plugins (some are built-in, others are cloned)
PLUGINS_TO_ENABLE=(
    git
    podman
    ssh-agent
    toolbox
    fzf
    zsh-interactive-cd
    ohmyzsh-full-autoupdate
    zsh-autosuggestions
    zsh-syntax-highlighting
    you-should-use
)

# --- Helper Functions ---
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

# --- Script Start ---
log_info "Starting Zsh environment configuration on Fedora 42..."

# 1. Install system dependencies (Zsh, git, curl, wget, fontconfig, fzf)
log_info "Installing system dependencies (zsh, git, curl, wget, fontconfig, util-linux-user, fzf)..."
sudo dnf update && dnf install -y zsh git curl wget fontconfig util-linux-user fzf unzip

# 2. Install JetBrainsMono Nerd Font
log_info "Installing JetBrainsMono Nerd Font..."
if [ -d "$FONT_INSTALL_DIR" ]; then
    log_info "JetBrainsMono Nerd Font seems to be already installed in $FONT_INSTALL_DIR."
else
    TEMP_FONT_DIR=$(mktemp -d)
    log_info "Downloading JetBrainsMono Nerd Font from $JETBRAINS_MONO_NERD_FONT_URL..."
    if wget -q --show-progress -O "$TEMP_FONT_DIR/JetBrainsMono.zip" "$JETBRAINS_MONO_NERD_FONT_URL"; then
        sudo mkdir -p "$FONT_INSTALL_DIR"
        log_info "Extracting font to $FONT_INSTALL_DIR..."
        sudo unzip -q "$TEMP_FONT_DIR/JetBrainsMono.zip" -d "$FONT_INSTALL_DIR"
        # Remove non-font files (e.g., OFL.txt, README.md) to keep it clean
        sudo find "$FONT_INSTALL_DIR" -type f ! -name "*.ttf" ! -name "*.otf" -delete
        log_info "Updating font cache..."
        sudo fc-cache -fv
        log_info "JetBrainsMono Nerd Font installed successfully."
    else
        log_error "Could not download the font. Check the URL or your internet connection."
    fi
    rm -rf "$TEMP_FONT_DIR"
fi

# 3. Install Oh My Zsh
log_info "Installing Oh My Zsh..."
if [ -d "$OH_MY_ZSH_DIR" ]; then
    log_info "Oh My Zsh is already installed in $OH_MY_ZSH_DIR."
else
    # Use --unattended to avoid prompts during OMZ installation
    # CHSH=no and RUNZSH=no so it doesn't try to change the shell or start zsh immediately
    CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_info "Oh My Zsh installed."
fi

# Ensure .zshrc exists (OMZ creates it if it doesn't)
if [ ! -f "$HOME/.zshrc" ]; then
    log_error "The ~/.zshrc file was not created by Oh My Zsh. Something went wrong."
    exit 1
fi

# 4. Install Powerlevel10k
P10K_THEME_DIR="${OH_MY_ZSH_DIR}/custom/themes/powerlevel10k"
log_info "Installing Powerlevel10k theme..."
if [ -d "$P10K_THEME_DIR" ]; then
    log_info "Powerlevel10k is already installed in $P10K_THEME_DIR."
    (cd "$P10K_THEME_DIR" && git pull) # Try to update if it already exists
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_THEME_DIR"
    log_info "Powerlevel10k installed."
fi

# Set Powerlevel10k as the theme in .zshrc
log_info "Configuring Powerlevel10k as theme in ~/.zshrc..."
sed -i 's|^ZSH_THEME=".*"|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"

# Configure ohmyzsh-full-autoupdate to not update OMZ core
# This variable must be defined BEFORE Oh My Zsh loads plugins.
AUTOUPDATE_CONFIG_LINE='export ZSH_CUSTOM_FULL_AUTOUPDATE_INHIBIT_OMZ_UPDATE=true'
if ! grep -qF "$AUTOUPDATE_CONFIG_LINE" "$HOME/.zshrc"; then
    log_info "Configuring ohmyzsh-full-autoupdate to not update OMZ core..."
    # Insert configuration before the line "source $ZSH/oh-my-zsh.sh"
    # or at the beginning of the file if that line is not found (less likely)
    if grep -q "source \$ZSH/oh-my-zsh.sh" "$HOME/.zshrc"; then
        sed -i "/source \$ZSH\/oh-my-zsh.sh/i $AUTOUPDATE_CONFIG_LINE" "$HOME/.zshrc"
    else
        # As a fallback, add to the beginning of the file if the source line is not there.
        # Or right after ZSH_THEME if it has already been configured
        if grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
             sed -i "/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/a $AUTOUPDATE_CONFIG_LINE" "$HOME/.zshrc"
        else
            # If ZSH_THEME is not found, add to the beginning of the file.
            # This is a slightly more generic fallback.
            echo "$AUTOUPDATE_CONFIG_LINE" | cat - "$HOME/.zshrc" > temp && mv temp "$HOME/.zshrc"
        fi
    fi
    log_info "ZSH_CUSTOM_FULL_AUTOUPDATE_INHIBIT_OMZ_UPDATE configuration added to ~/.zshrc."
else
    log_info "ZSH_CUSTOM_FULL_AUTOUPDATE_INHIBIT_OMZ_UPDATE is already configured in ~/.zshrc."
fi


# 5. Install Zsh Plugins (custom)
log_info "Installing custom Zsh plugins..."
mkdir -p "$ZSH_CUSTOM_PLUGINS_DIR"

# zsh-autosuggestions
PLUGIN_DIR_AUTOSUGGESTIONS="${ZSH_CUSTOM_PLUGINS_DIR}/zsh-autosuggestions"
if [ -d "$PLUGIN_DIR_AUTOSUGGESTIONS" ]; then
    log_info "zsh-autosuggestions plugin already installed. Updating..."
    (cd "$PLUGIN_DIR_AUTOSUGGESTIONS" && git pull)
else
    log_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR_AUTOSUGGESTIONS"
fi

# zsh-syntax-highlighting
PLUGIN_DIR_SYNTAX_HIGHLIGHTING="${ZSH_CUSTOM_PLUGINS_DIR}/zsh-syntax-highlighting"
if [ -d "$PLUGIN_DIR_SYNTAX_HIGHLIGHTING" ]; then
    log_info "zsh-syntax-highlighting plugin already installed. Updating..."
    (cd "$PLUGIN_DIR_SYNTAX_HIGHLIGHTING" && git pull)
else
    log_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR_SYNTAX_HIGHLIGHTING"
fi

# you-should-use
PLUGIN_DIR_YOU_SHOULD_USE="${ZSH_CUSTOM_PLUGINS_DIR}/you-should-use"
if [ -d "$PLUGIN_DIR_YOU_SHOULD_USE" ]; then
    log_info "you-should-use plugin already installed. Updating..."
    (cd "$PLUGIN_DIR_YOU_SHOULD_USE" && git pull)
else
    log_info "Installing you-should-use..."
    git clone https://github.com/MichaelAquilina/zsh-you-should-use "$PLUGIN_DIR_YOU_SHOULD_USE"
fi

# ohmyzsh-full-autoupdate
PLUGIN_DIR_OMZ_FULL_AUTOUPDATE="${ZSH_CUSTOM_PLUGINS_DIR}/ohmyzsh-full-autoupdate"
if [ -d "$PLUGIN_DIR_OMZ_FULL_AUTOUPDATE" ]; then
    log_info "ohmyzsh-full-autoupdate plugin already installed. Updating..."
    (cd "$PLUGIN_DIR_OMZ_FULL_AUTOUPDATE" && git pull)
else
    log_info "Installing ohmyzsh-full-autoupdate..."
    git clone https://github.com/Pilaton/OhMyZsh-full-autoupdate.git "$PLUGIN_DIR_OMZ_FULL_AUTOUPDATE"
fi


# 6. Configure plugins in .zshrc
log_info "Configuring plugins in ~/.zshrc..."
PLUGINS_LINE="plugins=($(printf "%s " "${PLUGINS_TO_ENABLE[@]}" | sed 's/ $//'))" # Build the plugins line

if grep -q "^plugins=(" "$HOME/.zshrc"; then
    # If the plugins=(...) line already exists, we replace it
    sed -i "s/^plugins=(.*)/${PLUGINS_LINE}/" "$HOME/.zshrc"
    log_info "Plugin list updated in ~/.zshrc."
else
    # If it doesn't exist, we add it (this is less likely with OMZ)
    # Ensure it's added before "source $ZSH/oh-my-zsh.sh" if possible
    if grep -q "source \$ZSH/oh-my-zsh.sh" "$HOME/.zshrc"; then
        sed -i "/source \$ZSH\/oh-my-zsh.sh/i $PLUGINS_LINE" "$HOME/.zshrc"
    else
        echo "${PLUGINS_LINE}" >> "$HOME/.zshrc"
    fi
    log_warn "'plugins=(...)' line not found, added to ~/.zshrc."
fi

# 7. Change default shell to Zsh
ZSH_PATH=$(which zsh)
if [ "$SHELL" != "$ZSH_PATH" ]; then
    log_info "Changing default shell to Zsh ($ZSH_PATH)..."
    # chsh might ask for password
    if sudo chsh -s "$ZSH_PATH" "$USER"; then
        log_info "Default shell changed to Zsh."
        log_warn "You will need to log out and log back in for the shell change to take effect."
    else
        log_error "Could not change default shell. Try manually with: sudo chsh -s $ZSH_PATH $USER"
    fi
else
    log_info "Zsh is already your default shell."
fi

# 8. Check if .p10k.zsh file exists in ~
if [ ! -f ~/.p10k.zsh ]; then
    echo "The ~/.p10k.zsh file does not exist. Moving and renaming p10k.zsh..."
    # Move the p10k.zsh file to the ~ directory and rename it to .p10k.zsh
    mv p10k.zsh ~/.p10k.zsh
    echo "p10k.zsh file moved and renamed to ~/.p10k.zsh"
else
    echo "The ~/.p10k.zsh file already exists. No movement was performed."
fi

# 9. Check if the .zshrc file has the source line for .p10k.zsh
if ! grep -q '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' ~/.zshrc; then
    echo "The source line for .p10k.zsh was not found in ~/.zshrc. Adding it..."
    # Add the line to the end of the .zshrc file
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
    echo "Line added to ~/.zshrc."
else
    echo "The source line for .p10k.zsh already exists in ~/.zshrc. No addition was performed."
fi

# --- End of Script ---
log_info "---------------------------------------------------------------------"
log_info "Installation complete!"
log_info "Next steps:"
log_info "1. Configure your terminal to use the 'JetBrainsMono Nerd Font'."
log_info "   (In GNOME Terminal: Preferences -> Profile -> Text -> Custom font)"
log_info "2. Close this terminal and open a new one, or log out and log back in."
log_info "3. The first time you open Zsh with Powerlevel10k, the configuration wizard will run."
log_info "   Answer the questions to customize your prompt: \`p10k configure\` if it doesn't start automatically."
log_info "4. If something doesn't work as expected, check the ~/.zshrc file."
log_info "   Verify that ZSH_CUSTOM_FULL_AUTOUPDATE_INHIBIT_OMZ_UPDATE=true is present."
log_info "---------------------------------------------------------------------"

exit 0
