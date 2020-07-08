
export WHYP_SOURCE=$BASH_SOURCE
export WHYP_DIR=$(dirname $(readlink -f $WHYP_SOURCE))
export WHYP_BIN=$WHYP_DIR/bin
export WHYP_VENV=
[[ -d $WHYP_DIR/.venv ]] && WHYP_VENV=$WHYP_DIR/.venv
[[ -d $WHYP_VENV ]] || WHYP_VENV=~/.virtualenvs/whyp
export WHYP_PY=$WHYP_DIR/whyp


