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
files="zshrc vim"      # list of files/folders to symlink in homedir
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
echo-ok "...done"