#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C
component=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ ${1:-} == prepare && $# == 1 ]]
tree="$component/src/upstream/orangefox-android16"
mkdir -p "$component/build" "$tree"
fetch() {
    local path="$tree/$1" url=$2 pin=$3
    [[ ! -e $path && ! -L $path ]] || {
        printf 'Refusing to replace existing source: %s\n' "$1" >&2
        return 1
    }
    git init -q "$path"
    git -C "$path" fetch --depth=1 --no-tags "$url" "$pin"
    git -C "$path" checkout --detach -q FETCH_HEAD
    [[ $(git -C "$path" rev-parse HEAD) == "$pin" ]]
}
fetch bootable/recovery https://gitlab.com/OrangeFox/bootable/Recovery.git 3d733672081bca3af42475a286145f4a8cdce4e7
fetch system/vold https://gitlab.com/OrangeFox/system/vold.git 953de9608eb78380b3c4e39e801c2bc0af7dbddc
for kind in recovery vold; do
    path="$tree/system/vold"
    [[ $kind != recovery ]] || path="$tree/bootable/recovery"
    bash "$component/scripts/prepare-reviewed-patches.sh" "$path" apply "$kind"
    bash "$component/scripts/prepare-reviewed-patches.sh" "$path" check "$kind"
done
fetch external/sqlite https://gitlab.com/OrangeFox/external/sqlite.git 28e3f5878182658a5c34d3ce0859e950f2885aba
fetch prebuilts/clang/host/linux-x86 https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 2d4dcbff7cb42f360f368bacf51cfe711fd1cb0f
compiler="$tree/prebuilts/clang/host/linux-x86/clang-r547379/bin/clang++"
[[ $(sha256sum "$compiler" | cut -d' ' -f1) == 55d80d777d85327543868817fb836231691eae2e13030ab31a01a769a820bf2f ]]
printf '%s\n' 'Pinned recovery/vold patches and host compiler prepared; no full Android source sync or image build.'
