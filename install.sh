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

function install_vim_links()
{
    deldotVimrc=n
    deldotVim=n
    if [ -f ~/.vimrc ]
    then
        read -p ".vimrc exists on your home. Delete? (y/n) " -n1 deldotVimrc
        echo
    fi

    if [ -d ~/.vim ]
    then
        read -p "There is already a .vim folder. Override? (y/n) " -n1 deldotVim
        echo
    fi

    if [ $deldotVimrc = "y" ]
    then
        echo-info "deleting current ~/.vimrc file..."
        rm ~/.vimrc
    fi

    if [ $deldotVim = "y" ]
    then
        echo-info "deliting current ~/.vim folder..."
        rm -rf ~/.vim
    fi

    if [ ! -d ~/.vim ]
    then
        ln -s $SCRIPT_PATH/vim ~/.vim
        echo-ok "installed .vim link."
    else
        echo-skip "Skipped ~/.vim will not be overwritten"
    fi
}

function install_scripts_link()
{
    action="c"
    if [ -e ~/bin ]
    then
        read -p "There is already a folder/file called bin on your home directory. Override(o)/Copy to existing folder(e)/Cancel(c)? " -n1 action 
    fi 

    if [ $action = "o" ]
    then
        echo-info "Deleting existing ~/bin..."
        rm -rf ~/bin 
    fi

    if [ -e ~/bin ]
    then
        if [ $action = "e" ]
        then
            cp $SCRIPT_PATH/scripts/* ~/bin
            echo-ok "Coppied scripts into existing ~/bin"
        else
            echo-skip "Skipped installing scripts"
        fi
    else
        ln -s $SCRIPT_PATH/scripts ~/bin 
        echo-ok "Installed scripts in ~/bin"
    fi
}


SCRIPT_PATH=$(cd `dirname $0` | pwd)
while [ 1 ]
do
    echo ==================================================
    echo Dotfiles
    echo ==================================================

    echo-option "1) Install vim configuration"
    echo-option "2) Install scripts"
    echo-option "3) Install all"
    echo-option "4) Exit"

    read -r option
    case $option in
        "1") install_vim_links;;
        "2") install_scripts_link;;
        "3")
            install_vim_links
            install_scripts_link
            ;;
        "4") break;;
    esac
done

