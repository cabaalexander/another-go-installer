#!/bin/bash -e

# another-go-installer

GOLANG_ORG_DL_PAGE=$(mktemp)
DOWNLOADED_FILE=$(mktemp)

trap '{ rm -f $DOWNLOADED_FILE $GOLANG_ORG_DL_PAGE ; }' SIGINT SIGTERM EXIT

GOROOT="$HOME/.go"
GOPATH="$HOME/go"

OS_NAME=$(uname -s | tr "[:upper:]" "[:lower:]")
OS_ARCH=$(
    if [ "$(uname -m)" = "x86_64" ]; then
        echo "amd64"
    else
        echo "386"
    fi
)
SYSTEM="${OS_NAME}-${OS_ARCH}"

SHELL_PROFILE="${HOME}/.$(basename "$SHELL")rc"

ENV_VARS=$(
cat <<EOF
# GoLang
export GOROOT="$GOROOT"
export GOPATH="$GOPATH"
export PATH="\$PATH:$GOROOT/bin:$GOPATH/bin"
EOF
)

__show_help(){
local NAME BOLD NORMAL

NAME="another-go-installer"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

cat <<EOF
${BOLD}NAME${NORMAL}
    $NAME - Installs the latest version of GoLang and create a workspace

${BOLD}USAGE${NORMAL}
    ${BOLD}$NAME${NORMAL} <OPTION>

${BOLD}OPTIONS${NORMAL}
    -${BOLD}i${NORMAL}      Installs GoLang
    -${BOLD}r${NORMAL}      Remove ALL things GoLang related (Not the workspace)

${BOLD}AUTHOR${NORMAL}
    Written by Alexander Caba

${BOLD}SEE ALSO${NORMAL}
    My dotfiles at: https://github.com/cabaalexander/dotfiles
EOF
}

__sanitize(){
    sed -E 's:([$\/]):\\\1:g' <<<"$1"
}

__remove_env_vars(){
    local LINE FILE SANITIZED_LINE MATCH
    FILE=$1

    test -z "$FILE" && return 1

    while read -rs LINE; do
        SANITIZED_LINE=$(__sanitize "$LINE")
        MATCH="$(sed -En "/^($SANITIZED_LINE)$/p" "$FILE")"

        # Don't match blank(s) [base condition]
        test -z "$MATCH" && continue

        # If the file is a symlink, follow it
        if [ -L "$FILE" ]; then
            FILE=$(readlink "$FILE")
        fi

        # Verbosity
        test -n "$MATCH" && echo "[Deleted] $MATCH"

        # For mac issues ¯\\_(ツ)_/¯
        case "$OS_NAME" in
            linux)
                sed -i -E "/^($SANITIZED_LINE)$/d" "$FILE"
                ;;
            darwin)
                sed -i '' -E "/^($SANITIZED_LINE)$/d" "$FILE"
                ;;
            *) echo "Script not supported for OS: $OS_NAME"
        esac
    done <<<"$ENV_VARS"
}

__validate_checksum(){
    local TO_DOWNLOAD DOWNLOADED LOCAL_SHA_CHECKSUM \
        REMOTE_SHA_CHECKSUM GO_VERSION_DL_LINE

    TO_DOWNLOAD=$1
    DOWNLOADED=$2

    GO_VERSION_DL_LINE=$(
        nl -ba < "$GOLANG_ORG_DL_PAGE" |
            grep -E "$TO_DOWNLOAD" |
            tail -1 |
            awk '{print $1}'
    )

    REMOTE_SHA_CHECKSUM=$(
        awk "NR > $GO_VERSION_DL_LINE && NR < $((GO_VERSION_DL_LINE + 9)) \
            {print}" < "$GOLANG_ORG_DL_PAGE" |
                grep -E '<tt>' |
                sed -E 's:.*<tt>(.*)</tt>.*:\1:'
    )

    LOCAL_SHA_CHECKSUM=$(openssl dgst -sha256 "$DOWNLOADED" | cut -d' ' -f2)

    if [ "$LOCAL_SHA_CHECKSUM" != "$REMOTE_SHA_CHECKSUM" ]; then
        echo "SHA256 Checksum ❌ " 1>&2
        exit 1
    else
        echo "SHA256 Checksum ✔"
    fi
}

__uninstall(){
    if ! [ -d "$GOROOT" ]; then
        echo "Golang not installed..."
        exit 0
    fi

    echo -n "Uninstalling... "
    rm -rf "$GOROOT"
    echo
    __remove_env_vars "$SHELL_PROFILE"
    echo "Go uninstalled."
}

__get_all_versions(){
    grep -E "$OS_NAME" "$GOLANG_ORG_DL_PAGE" |
        grep -E 'go1.' |
        grep -v 'span' |
        sed -E 's/^.*href="(.*).*\/go([0-9](\.[0-9]+)+).*$/\1 \2/' |
        uniq
}

__validate_version(){
    local VERSION
    VERSION=$1

    if [ -z "$VERSION" ]; then
        return
    fi

    ALL_VERSIONS=$(__get_all_versions | cut -d' ' -f2)
    FOUND_VERSION=$(grep -E "^$VERSION$" <<<"$ALL_VERSIONS" | head -1)

    if [ -z "$FOUND_VERSION" ] ; then
        exec 3>&1 1>&2
        echo "Version $VERSION not found..."
        echo
        read -n1 -rsp "Show a list of available versions? [y\\n]" ANSWER
        if [[ $ANSWER =~ ^[yY]$ ]]; then
            echo "$ALL_VERSIONS"
        fi
        exec 1>&3
        exit 1
    else
        echo "$FOUND_VERSION"
    fi
}

__install(){
    if [ -d "$GOROOT" ]; then
        echo "You have GoLang already installed m8... ¯\\_(ツ)_/¯" 1>&2
        exit 1
    fi

    local \
        ENDPOINT_AND_VERSION \
        ENDPOINT \
        GO_LATEST_VERSION \
        FILE_TO_DOWNLOAD \
        ARG_VERSION
    curl -s https://golang.org/dl/ > "$GOLANG_ORG_DL_PAGE"

    ARG_VERSION=$(__validate_version "$1") || exit 1

    ENDPOINT_AND_VERSION=$(__get_all_versions | head -1)

    ENDPOINT=$(cut -d' ' -f1 <<<"$ENDPOINT_AND_VERSION")
    GO_LATEST_VERSION=$(cut -d' ' -f2 <<<"$ENDPOINT_AND_VERSION")
    DOWNLOAD_VERSION=${ARG_VERSION:-$GO_LATEST_VERSION}

    if [ -z "$DOWNLOAD_VERSION" ]; then
        echo "The version of GoLang could not be verified..." 1>&2
        exit 1
    fi

    FILE_TO_DOWNLOAD="go${DOWNLOAD_VERSION}.${SYSTEM}.tar.gz"

    echo -en "Downloading Golang ${DOWNLOAD_VERSION}\n... "
    if curl -sL "${ENDPOINT}/${FILE_TO_DOWNLOAD}" > "$DOWNLOADED_FILE"; then
        echo "Finished."
    else
        echo -e "\n\nSomething happened while downloading! Try later." 1>&2
        exit 1
    fi

    # Checks if openssl is available on the system for checksum validation
    if command -v openssl &> /dev/null; then
        echo "Validating checksum..."
        __validate_checksum "$FILE_TO_DOWNLOAD" "$DOWNLOADED_FILE"
    else
        echo "openssl not installed, please install and re-run" 1>&2
        exit 1
    fi

    echo "Extracting file... "
    tar -xzf "$DOWNLOADED_FILE" -C /tmp/
    mv -f /tmp/go "$GOROOT"

    # Create GoLang workspace
    mkdir -vp "$GOPATH"/{bin,src,pkg}

    if ! [ "$QUIET" ]; then
        # Add environment variables to the current shell *rc
        touch "$SHELL_PROFILE"
        echo "Added these variables to your $SHELL_PROFILE file"
        echo "$ENV_VARS" | tee -a "$SHELL_PROFILE"
    fi

    # Final message
    echo -e "\nGolang version ${DOWNLOAD_VERSION} was installed. Restart your terminal to see changes."
}

goInstall(){
    local MAPPER

    while getopts ":i:rhq" OPT; do
        case $OPT in
            h) MAPPER="__show_help" ;;
            i) MAPPER="__install $OPTARG" ;;
            r) MAPPER="__uninstall" ;;
            q) QUIET="yup" ;;
            *) # do default stuff ;;
        esac
    done
    shift $((OPTIND - 1))

    eval "${MAPPER:-__install}"
}

# If this file is running in terminal call the function `goInstall`
# Otherwise just source it
if [ "$(basename "$0")" = "another-go-installer.sh" ]
then
    goInstall "${@}"
fi
