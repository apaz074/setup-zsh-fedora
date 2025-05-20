# Setup Zsh Fedora

This repository contains a bash script to automate the setup of a powerful Zsh environment on Fedora 41 or later. The script installs Zsh, Oh My Zsh, Powerlevel10k theme, and several useful plugins like zsh-autosuggestions and zsh-syntax-highlighting. It also configures the JetBrainsMono Nerd Font.

## Prerequisites

- Fedora 41 or later operating system
- Internet connection
- User with sudo privileges

## Usage

1. Clone this repository:

   Choose one of the following options to clone the repository:

   **HTTPS:**
   ```bash
   git clone https://github.com/apaz074/setup-zsh-fedora.git
   ```

   **SSH:**
   ```bash
   git clone git@github.com:apaz074/setup-zsh-fedora.git
   ```

   **GitHub CLI:**
   ```bash
   gh repo clone apaz074/setup-zsh-fedora
   ```

2. Navigate to the repository directory:
   ```bash
   cd setup-zsh-fedora
   ```

3. Make the script executable:
   ```bash
   chmod +x setup_zsh_fedora.sh
   ```

4. Run the script:
   ```bash
   ./setup_zsh_fedora.sh
   ```

5. The script will guide you through the installation process. You may be prompted for your password for sudo operations.

6. After the script finishes, you will need to close your current terminal and open a new one, or log out and log back in for the changes to take effect.

7. The first time you open Zsh with Powerlevel10k, the configuration wizard will run. Follow the prompts to customize your terminal appearance. You can also run `p10k configure` later if needed.

## What the script does:

- Installs necessary system dependencies (zsh, git, curl, wget, fontconfig, util-linux-user, fzf, unzip).
- Installs the JetBrainsMono Nerd Font.
- Installs Oh My Zsh.
- Installs the Powerlevel10k theme.
- Configures Powerlevel10k as the default theme.
- Configures ohmyzsh-full-autoupdate plugin.
- Installs custom Zsh plugins (zsh-autosuggestions, zsh-syntax-highlighting, you-should-use, ohmyzsh-full-autoupdate).
- Configures the installed plugins in `~/.zshrc`.
- Changes the default shell to Zsh.
- Checks for and moves the `p10k.zsh` file from the script's directory to `~/.p10k.zsh` if it doesn't exist.
- Adds a source line for `~/.p10k.zsh` to `~/.zshrc` if it's not already present.
