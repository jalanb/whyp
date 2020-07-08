byt () {
    local lang_=
    [[ $1 =~ [.][ps][yh]$ ]] || return 1
    [[ $1 =~ [.]py$ ]] && lang_="-l Python"
    [[ $lang_ ]] && shift
    [[ $1 =~ [.]sh$ ]] && lang_="-l bash"
    local first_= last_=
    [[ $1 =~ ^[0-9][0-9]*$ ]] && first_="$1"
    [[ $lang_ ]] && shift
    [[ $1 =~ ^[0-9][0-9]*$ ]] && last_="$1"
    [[ $first_ ]] && options_="--first $first_"
    [[ $last_ ]] && kat_options_="$kat_options_--last $last_"
    bat "$@" | \
        sed -e '/ is a /d' |\
        kat -n $kat_options_| \
        bat $lang_
}

byt.py () {
    byt .py "$@"
}

byt.sh () {
    byt .sh "$@"
}

psbash () {
    psw bash[3-9]*
}

uniqs () {
    sort | uniq
}

sed_subs () {
    sed -e 's,'"$1"','"$2"','
}

lstrip () {
    sed_subs '^'"$1" "$2"
}

rstrip () {
    sed_subs "$1$" "$2"
}

strips () {
    lstrip | rstrip
}

strips () {
    local lstrip_="$1", rstrip="$2"; shift 2
    echo "$@" | sed -e "s$lstrip_" -e "s$rstrip_"
}

psgrep () {
    local main_="$1"; shift
    grep --color g [/][a-z/]*"$main_"*
}


# main_=bash
# ps -ef | psgrep "$main_" | lstrip " [/]" "/" | rstrip "[ ]" | uniqs
#
psw () {
    local main_=$1
    local app_re_="[/][a-z/]*$main_*"
    [[ $main_ ]] || psbash
    ps -ef | psgrep "$main_" | strips ",.* [/],/," ",[ ].*,," | uniqs
}


