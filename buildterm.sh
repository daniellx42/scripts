#!/bin/bash
#!/bin/sh

ohmyzsh="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
plugins="git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete"
clone_plugins=(
    "https://github.com/zsh-users/zsh-autosuggestions.git"
    "https://github.com/zsh-users/zsh-syntax-highlighting.git"
    "https://github.com/zdharma-continuum/fast-syntax-highlighting.git"
    "https://github.com/marlonrichert/zsh-autocomplete.git")
themes_path=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "fast-syntax-highlighting"
    "zsh-autocomplete")
histsize_histfile="
### variables zsh histsize and histfile
export HISTSIZE=100000
export SAVEHIST=$HISTSIZE
export SAVESIZE=100000
export HISTCONTROL=ignoredups:ignorespace
# exa
alias ls=\"exa --icons\"
"
# colors
CYAN='\e[96m'$(printf "\e[96m")
GREEN=$(printf "\e[1;32m")
END=$(printf "\e[0m")
SUCCESS=$(printf "\e[1;32m [ OK ] \e[0m")
ERROR=$(printf "\e[1;31m [ ERROR ] \e[0m")

select_option() {
    # colors

    # little helpers for terminal print control and key input
    ESC=$(printf "\033")
    cursor_blink_on() { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to() { printf "$ESC[$1;${2:-1}H"; }
    print_option() { printf "$GREEN   $1 $END"; }
    print_selected() { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row() {
        IFS=';' read -sdR -p $'\E[6n' ROW COL
        echo ${ROW#*[}
    }
    key_input() {
        read -s -n3 key 2>/dev/null >&2
        if [[ $key = "${ESC}[A" ]]; then echo up; fi
        if [[ $key = "${ESC}[B" ]]; then echo down; fi
        if [[ $key = "" ]]; then echo enter; fi
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=$(get_cursor_row)
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
        enter) break ;;
        up)
            ((selected--))
            if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi
            ;;
        down)
            ((selected++))
            if [ $selected -ge $# ]; then selected=0; fi
            ;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

main() {
    clear
    ### install dependencies
    sudo pacman -S git zsh alacritty base-devel
    # install yay
    git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si
    # install rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    # install icons eza
    cargo install eza
    # instalar fonts
    sudo pacman -S noto-fonts ttf-hack ttf-ubuntu-font-family ttf-fira-code
    # instalar ícons
    sudo pacman -S papirus-icon-theme adwaita-icon-theme
    ### install oh-my-zsh
    sh -c "$(curl -fsSL $ohmyzsh)"
    ### theme and plugins
    echo "Escolha um tema:"
    options=("robbyrussell" "xiong-chiamiov-plus")
    select_option "${options[@]}"
    choice=$?

    for ((i = 0; i < ${#clone_plugins[@]}; i++)); do
        sudo git clone --depth 1 -- ${clone_plugins[i]} ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${themes_path[i]}
    done

    sed -i "s/^plugins=.*/plugins=(${plugins})/" ~/.zshrc
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"${options[$choice]}\"/" ~/.zshrc
    echo -e "${options[$choice]} $SUCCESS"
    echo "$histsize_histfile" >>~/.zshrc
    echo -e "added variables $SUCCESS"
    echo -e "$GREEN Finished $END $SUCCESS"
}

main
