#!/bin/bash

echo ================================================== 
echo Installing dotfiles...
echo ================================================== 
echo
echo

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
    echo "deleting current ~/.vimrc file..."
    rm ~/.vimrc
fi

if [ $delVimrc = "y" ]
then
    echo "deliting current ~/.vim/vimrc file..."
    rm ~/.vim/vimrc
fi

if [ ! -d ~/.vim ]
then
    echo "~/.vim does not exist. Creating..."
    mkdir ~/.vim
fi

echo "installing ~/.vim/vimrc..."
cp vimrc ~/.vim/vimrc

echo done!
