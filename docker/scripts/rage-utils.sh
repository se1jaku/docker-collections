#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOF
Usage:
    $0 encrypt <src_dir> <dst_dir> [pattern]
    $0 decrypt <src_dir> <dst_dir> [pattern]

Examples:
    $0 encrypt ./configs ./encrypted
    $0 encrypt ./configs ./encrypted '*.json'

    $0 decrypt ./encrypted ./restored
    $0 decrypt ./encrypted ./restored '*.age'

Env:
    RAGE_PASSPHRASE=your-passphrase

Notes:
    - Hidden files (.*/.*) are skipped
    - Output files are overwritten
EOF
}

# ----------------------------
# arg check
# ----------------------------
if (( $# < 3 || $# > 4 )); then
    usage
    exit 1
fi

MODE="$1"
SRC_DIR="$2"
DST_DIR="$3"
PATTERN="${4:-}"

case "$MODE" in
    encrypt|decrypt) ;;
    *)
        usage
        exit 1
        ;;
esac

if [[ ! -d "$SRC_DIR" ]]; then
    echo "Source dir not found: $SRC_DIR" >&2
    exit 1
fi

SRC_DIR="$(cd "$SRC_DIR" && pwd -P)"

if [[ -z "$PATTERN" && "$MODE" == "decrypt" ]]; then
    PATTERN="*.age"
fi

if [[ -z "${RAGE_PASSPHRASE:-}" ]]; then
    read -rsp "Passphrase: " RAGE_PASSPHRASE
    echo
fi

export RAGE_PASSPHRASE
export PINENTRY_PROGRAM=""
export LC_ALL=C

# ----------------------------
# file discovery
# ----------------------------
find_files() {
    if [[ -n "$PATTERN" ]]; then
        find "$SRC_DIR" \
            -type d -name '.*' -prune -o \
            -type f ! -name '.*' -name "$PATTERN" -print0
    else
        find "$SRC_DIR" \
            -type d -name '.*' -prune -o \
            -type f ! -name '.*' -print0
    fi
}

# ----------------------------
# rage via expect
# ----------------------------
rage_encrypt() {
    local src="$1"
    local dst="$2"

    PINENTRY_PROGRAM="" expect <<EOF
log_user 0
spawn rage -e -p -o "$dst" "$src"

expect -re {Type passphrase.*}
send -- "$RAGE_PASSPHRASE\r"

expect -re {Confirm passphrase.*}
send -- "$RAGE_PASSPHRASE\r"

expect eof
EOF
}

rage_decrypt() {
    local src="$1"
    local dst="$2"

    local status=0

    PINENTRY_PROGRAM="" expect <<EOF || status=$?
log_user 0
set timeout -1

spawn rage -d -o "$dst" "$src"

expect {
    -re {Type passphrase.*} {
        send -- "$RAGE_PASSPHRASE\r"
        exp_continue
    }

    eof {
        catch wait result
        exit [lindex \$result 3]
    }
}
EOF

    return "$status"
}

# ----------------------------
# file processors
# ----------------------------
encrypt_file() {
    local src="$1"
    local rel="${src#$SRC_DIR/}"
    local dst="$DST_DIR/$rel.age"

    mkdir -p "$(dirname "$dst")"

    rage_encrypt "$src" "$dst"

    echo "[rage-utils] encrypting $rel"
}

decrypt_file() {
    local src="$1"
    local rel="${src#$SRC_DIR/}"
    rel="${rel%.age}"
    local dst="$DST_DIR/$rel"

    echo "[rage-utils] decrypting $rel"
    set +e
    rage_decrypt "$src" "$dst"
    local status=$?
    set -e

    if (( status != 0 )); then
        echo "[rage-utils] decryption failed for $rel" >&2
        return "$status"
    else
        echo "[rage-utils] decryption finished for $rel"
    fi
}

# ----------------------------
# main loop
# ----------------------------
case "$MODE" in
    encrypt)
        while IFS= read -r -d '' file; do
            encrypt_file "$file"
        done < <(find_files)
        ;;
    decrypt)
        while IFS= read -r -d '' file; do
            decrypt_file "$file"
        done < <(find_files)
        ;;
esac
