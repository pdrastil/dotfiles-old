#!/usr/bin/env bash

# Dotfiles and bootstrap installer
# Installs git, clones dotfiles and symlinks dotfiles to your home

set -e
trap on_error SIGKILL SIGTERM

# User
export DOTFILES=${1:-"${HOME}/.dotfiles"}
export INTERACTIVE=${INTERACTIVE:="yes"}

# Defaults
DOTFILES_GITHUB_REPO='https://github.com/pdrastil/dotfiles'
HOMEBREW_INSTALLER_URL='https://raw.githubusercontent.com/Homebrew/install/master/install'

# Colors
esc='\033'
RESET="${esc}[0m"
BOLD="${esc}[1m"
CYAN="${esc}[0;96m"
RED="${esc}[0;91m"
YELLOW="${esc}[0;93m"
GREEN="${esc}[0;92m"

_cmd_exists() {
  type -p $1 > /dev/null
}

_package_exists() {
  brew info $1 > /dev/null
}

# Info reporter
info() {
  echo -e "${CYAN}${*}${RESET}"
}

# Success reporter
success() {
  echo -e "${GREEN}${*}${RESET}"
}

# Error reporter
error() {
  echo -e "${RED}${*}${RESET}"
}

# Question reporter
ask() {
  echo -e "${YELLOW}${*} [y/N]: ${RESET}"
}

# Handle user questions
choice() {
  local msg=$1 default=${2:-"yes"}
  if [[ "${INTERACTIVE}" != "yes" ]]; then
    return
  fi

  ask ${*} && read answer
  echo
  case ${answer:0:1} in
    '')
      export ANSWER="${default}"
    ;;
    y|Y)
      export ANSWER="yes"
    ;;
    *)
      export ANSWER="no"
    ;;
  esac
}

# End section
finish() {
  success "Done!"
  echo
  sleep 1
}

# Error handler
on_error() {
  echo
  echo -e '                      !#?  '
  echo -e '                     (\_/) '
  echo -e '                    (=^.^=)'
  echo -e '                    (")_(")'
  error "┌───────────────────────────────────────────────┐"
  error "│ Something serious happened!                   │"
  error "│ Though, I don't know what really happened...  │"
  error "└───────────────────────────────────────────────┘"
  info "Please raise an issue to help me fix this problem..."
  info "GitHub: ${DOTFILES_GITHUB_REPO}/issues/new"
  echo
  exit 1
}

# Install methods
install_start() {
  if [[ `uname` != 'Darwin' ]]; then
      error 'Installer is intended only for macOS!'
      exit 1
  fi

  info '         __      __  _______ __         '
  info '    ____/ /___  / /_/ ____(_) /__  _____'
  info '   / __  / __ \/ __/ /_  / / / _ \/ ___/'
  info ' _/ /_/ / /_/ / /_/ __/ / / /  __(__  ) '
  info '(_)__,_/\____/\__/_/   /_/_/\___/____/  '
  info '                                        '
  info '              by @pdrastil              '
  info '                                        '

  if [[ "${INTERACTIVE}" == "yes" ]]; then
    info 'Installer will guide you throught developer setup of your machine.'
    info 'It will not install anything without your direct consent!'
    echo
    choice "Do you want to proceed with installation? "
    echo
    if [[ "${ANSWER}" != "yes" ]]; then
        exit 1
    fi
  fi
}

install_finish() {
  echo -e '         YAY  '
  echo -e '        (\_/) '
  echo -e '       (=^.^=)'
  echo -e '       (")_(")'
  success "┌───────────────────┐"
  success "│ Success !!!       │"
  success "│ Happy Coding !!!  │"
  success "└───────────────────┘"
  echo
  info "P.S.: Don't forget to restart terminal :)"
  echo
}

install_cli_tools() {
  info "Trying to detect XCode Command Line Tools..."
  if [[ $(xcode-select -p ) ]]; then
    success "XCode Command Line Tools already installed."
  else
    info "XCode Commnad Line Tools not found..."
    choice "Install XCode Command Line Tools?"

    if [[ "${ANSWER}" != "yes" ]]; then
        exit 1
    fi

    info "Installing XCode Command Line Tools..."
    xcode-select --install
  fi
  finish
}

install_homebrew() {
  info "Trying to detect Homebrew..."
  if _cmd_exists brew; then
    success "Homebrew already installed."
  else
    info "Homebrew not found..."
    choice "Install Homebrew?"
    echo
    if [[ "${ANSWER}" != "yes" ]]; then
      exit 1
    fi

    info "Installing Homebrew..."
    ruby -e "$(curl -fsSL ${HOMEBREW_INSTALLER_URL})"
  fi

  info "Updating Homebrew..."
  brew update
  brew upgrade
  finish
}

install_git() {
  info "Trying to detect Git..."
  if ! _package_exists git; then
    success "Git already installed."
    return
  fi

  info "Git not found..."
  choice "Install Git?"
  echo
  if [[ "${ANSWER}" != "yes" ]]; then
    exit 1
  fi

  info "Installing Git..."
  brew install git git-lfs git-flow
  finish
}

install_zsh() {
  info "Trying to detect Zsh..."
  if _package_exists zsh; then
    success "Zsh already installed."
  else
    info "Zsh not found..."
    choice "Install Zsh?"

    if [[ "${ANSWER}" != "yes" ]]; then
      exit 1
    fi

    info "Installing Zsh..."
    brew install zsh zsh-completions
  fi
  finish
}

install_dotfiles(){
  info "Trying to detect dotfiles..."
  if [[ ! -d $DOTFILES ]]; then
    info "Dotfiles are not installed!"
    choice "Install dotfiles?"

    if [[ "${ANSWER}" != "yes" ]]; then
      exit 1
    fi

    git clone --recursive "${DOTFILES_GITHUB_REPO}" $DOTFILES
  else
    success "Dotfiles already installed. Skipping..."
  fi

  info "Linking dotfiles..."
  python $DOTFILES/sync.py
  finish
}

main() {
  install_start
  install_cli_tools
  install_homebrew
  install_zsh
  install_dotfiles
  install_finish
}

main "$*"
