#!/bin/bash

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

function install_vim_files {
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

    if [ ! -f ~/.vim/vimrc ]
    then
        cp vim/vimrc ~/.vim/vimrc
        echo-ok "installed vimrc."
    else
        echo-skip "Skipped vimrc. ~/.vim/vimrc will not be overwritten"
    fi

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
}

function install_scripts()
{
   if [ ! -d ~/bin ]
   then
       mkdir ~/bin
   fi 
   cp scripts/* ~/bin
   echo-ok "done installing scripts in ~/bin"
}


while [ 1 ]
do
    echo ==================================================
    echo Dotfiles
    echo ==================================================

    echo-option "1) Install vim configuration"
    echo-option "2) Install scripts"
    echo-option "3) Exit"

    read -r option
    case $option in
        "1") install_vim_files;;
        "2") install_scripts;;
        "3") break;;
    esac
done

