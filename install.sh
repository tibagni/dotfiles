#!/bin/bash
############################
# .install.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# from http://blog.smalleycreative.com/tutorials/using-git-and-github-to-manage-your-dotfiles/
############################

function echo-option    { printf "\r\033[2K\033[0;36m  -> \033[0m %s\n" "$*"; }
function echo-ok        { printf "\r\033[2K\033[0;32m[ OK ]\033[0m %s\n" "$*"; }
function echo-skip      { printf "\r\033[2K\033[38;05;240m[SKIP]\033[0m %s\n" "$*"; }
function echo-info      { printf "\r\033[2K\033[0;34m[ .. ]\033[0m %s\n" "$*"; }
function print-files {
    for file in $(ls $1)
    do
        echo-info "    $file "
    done
}

########## Variables
dir=~/dotfiles         # dotfiles directory
olddir=~/dotfiles_old  # old dotfiles backup directory
files="zshrc vim tmux.conf ideavimrc spacemacs"      # list of files/folders to symlink in homedir
##########

echo ==================================================
echo Dotfiles
echo ==================================================

# create dotfiles_old in homedir
echo-info "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo-ok "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
for file in $files; do
    echo-info "Moving any existing dotfiles from ~ to $olddir"
    mv ~/.$file ~/dotfiles_old/
    echo-info "Creating symlink to $file in home directory."
    ln -s $dir/$file ~/.$file
done

# install oh-my-zsh custom plugins
if [ -d ~/.oh-my-zsh ]
then
    echo-info "Installing oh-my-zsh custom plugins"

    echo-info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

    echo-info "Installing zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

# install vundle for vim plugin management
if [ -d ~/.vim ]
then
    echo-info "Installing vundle"

    echo-info "Downloading..."
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

    echo-info "Installing..."
    vim +PluginInstall +qall
fi

# install scripts folder. Bakcup old folder if exists first
if [ -d ~/scripts ]
then
    echo-info "Backing up old scripts folder..."
    mv ~/scripts ~/dotfiles_old/scripts
fi
echo-info "Installing scripts..."
ln -s $dir/scripts ~/scripts

echo-ok "...done"
