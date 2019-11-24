#!/bin/bash

function echo-ok    { printf "\r\033[2K\033[0;32m[ OK ]\033[0m %s\n" "$*"; }
function echo-info  { printf "\r\033[2K\033[0;34m[ .. ]\033[0m %s\n" "$*"; }

echo ================================================== 
echo Installing dotfiles...
echo ================================================== 

############################################################
# Vim dotfile
############################################################
deldotVimrc=n
delVimrc=n
if [ -f ~/.vimrc ]
then
    read -p ".vimrc exists on your home. Override? (y/n) " -n1 deldotVimrc
    echo
fi

if [ -f ~/.vim/vimrc ]
then
    read -p "vimrc exists on your .vim folder. Override? (y/n) " -n1 delVimrc
    echo
fi

if [ $deldotVimrc = "y" ]
then
    echo-info "deleting current ~/.vimrc file..."
    rm ~/.vimrc
fi

if [ $delVimrc = "y" ]
then
    echo-info "deliting current ~/.vim/vimrc file..."
    rm ~/.vim/vimrc
fi

if [ ! -d ~/.vim ]
then
    echo-info "~/.vim does not exist. Creating..."
    mkdir ~/.vim
fi

echo-info "installing ~/.vim/vimrc..."
cp vim/vimrc ~/.vim/vimrc

if [ ! -d ~/.vim/colors ]
then
    echo-info "creating the colors dir..."
    mkdir ~/.vim/colors
fi

echo-info "installing badwolf color scheme..."
cp vim/colors/badwolf.vim ~/.vim/colors/badwolf.vim

if [ ! -d ~/.vim/plugin ]
then
    echo-info "creating plugin folder..."
    mkdir ~/.vim/plugin
fi

# Install plugins
for plugin in $(ls vim/plugin)
do
    echo-info "installing $plugin..."
    cp vim/plugin/$plugin ~/.vim/plugin/$plugin
done

# Copy syntax files for CSyntaxAfter
if [ ! -d ~/.vim/after/syntax ]
then
    echo-info "creating syntax folder for CSyntaxAfter..."
    mkdir -p ~/.vim/after/syntax
fi
cp vim/after/syntax/* ~/.vim/after/syntax/


echo-ok "done!"
