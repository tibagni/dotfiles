#!/bin/bash

function echo-ok    { printf "\r\033[2K\033[0;32m[ OK ]\033[0m %s\n" "$*"; }
function echo-info  { printf "\r\033[2K\033[0;34m[ .. ]\033[0m %s\n" "$*"; }
function print-files {
    for file in $(ls $1)
    do
        echo-info "    $file "
    done
}

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

cp vim/vimrc ~/.vim/vimrc
echo-ok "installed vimrc."

if [ ! -d ~/.vim/colors ]
then
    mkdir ~/.vim/colors
fi

cp vim/colors/badwolf.vim ~/.vim/colors/badwolf.vim
echo-ok "installed badwolf color scheme"

# Install plugins
echo-info "installing plugins..."
print-files vim/plugin
if [ ! -d ~/.vim/plugin ]
then
    mkdir ~/.vim/plugin
fi

cp vim/plugin/* ~/.vim/plugin/

# Copy syntax files for CSyntaxAfter
if [ ! -d ~/.vim/after/syntax ]
then
    mkdir -p ~/.vim/after/syntax
fi
echo-info "installing CSyntaxAfter syntax files"
print-files vim/after/syntax
cp vim/after/syntax/* ~/.vim/after/syntax/
echo-ok "done installing plugins"

# Install syntax for other languages
echo-info "installing syntax files..."
print-files vim/syntax
if [ ! -d ~/.vim/syntax ]
then
    mkdir ~/.vim/syntax
fi

if [ ! -d ~/.vim/indent ]
then
    mkdir ~/.vim/indent
fi

if [ ! -d ~/.vim/ftdetect ]
then
    mkdir ~/.vim/ftdetect
fi
cp vim/syntax/* ~/.vim/syntax/
cp vim/indent/* ~/.vim/indent/
cp vim/ftdetect/* ~/.vim/ftdetect
echo-ok "done installing syntax files"


echo-ok "All done for vim!"
