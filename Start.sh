#!/bin/bash
cd "$(dirname "$0")" || exit 1
SERVER_DIR="./server"
mkdir -p "$SERVER_DIR"

# ANIMAZIONE CARICAMENTO
loader() {
    local pid=$1
    local spin='|/-\'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\rCaricamento versioni ${spin:$i:1} "
        sleep 0.2
    done
    printf "\r                        \r"
}

get_versions() {
    local url=$1
    local type=$2
    if [ "$type" = "paper" ]; then
        curl -fsSL "$url" 2>/dev/null | grep -o '"[0-9]\.[0-9][0-9]*\.[0-9]*"' | tr -d '"' | sort -V -r | head -10
    elif [ "$type" = "fabric" ]; then
        curl -fsSL "$url" 2>/dev/null | grep -o '"version":"[0-9]\.[0-9][0-9]*\.[0-9]*"' | cut -d'"' -f4 | sort -V -r | head -10
    fi
}

menu_versioni() {
    local type=$1
    local url=$2
    echo ""
    get_versions "$url" "$type" &
    loader $!
    wait $!

    mapfile -t vers < <(get_versions "$url" "$type")

    if [ ${#vers[@]} -eq 0 ]; then
        echo "ERRORE: Internet non va. Uso lista di emergenza"
        sleep 2
        [ "$type" = "paper" ] && vers=("1.20.6" "1.20.4" "1.19.4")
        [ "$type" = "fabric" ] && vers=("1.20.1" "1.19.4")
    fi

    clear
    echo "=== SCEGLI VERSIONE ==="
    for i in "${!vers[@]}"; do echo "$((i+1))) ${vers[$i]}"; done
    echo "0) Indietro"
    read -rp "Scegli: " c
    [ "$c" = "0" ] && echo "" && return
    echo "${vers[$((c-1))]}"
}

create_server() {
    clear
    echo "1) Paper  2) Fabric  0) Back"
    read -rp "Tipo: " t
    [ "$t" = "0" ] && return

    read -rp "Nome server: " name
    [ -z "$name" ] && return
    [ -d "$SERVER_DIR/$name" ] && echo "Esiste già!" && sleep 2 && return

    if [ "$t" = "1" ]; then
        version=$(menu_versioni "paper" "https://api.papermc.io/v2/projects/paper")
        [ -z "$version" ] && return
        type="paper"
    elif [ "$t" = "2" ]; then
        version=$(menu_versioni "fabric" "https://meta.fabricmc.net/v2/versions/game")
        [ -z "$version" ] && return
        type="fabric"
    fi

    mkdir -p "$SERVER_DIR/$name" && cd "$SERVER_DIR/$name"
    echo "Download $type $version..."

    if [ "$type" = "paper" ]; then
        curl -L -o server.jar "https://api.papermc.io/v2/projects/paper/versions/$version/builds/latest/downloads/paper-$version-latest.jar"
        echo -e "#!/bin/bash\njava -Xms512M -Xmx1G -jar server.jar --nogui" > start.sh
    elif [ "$type" = "fabric" ]; then
        curl -L -o server.jar "https://meta.fabricmc.net/v2/versions/loader/$version/latest/server/jar"
        echo -e "#!/bin/bash\njava -Xms512M -Xmx1G -jar server.jar --nogui" > start.sh
    fi

    echo "eula=true" > eula.txt
    chmod +x start.sh
    echo ""; echo "EVVIVA! $name creato!"
    read -rp "INVIO..."
}

open_server() { cd "$SERVER_DIR"; select d in */; do [ -n "$d" ] && bash "$d/start.sh"; break; done; }
delete_server() { cd "$SERVER_DIR"; select d in */; do [ -n "$d" ] && rm -rf "$d"; break; done; }

while true; do
    clear
    echo "=== MC-Orbit v3.5 ==="
    echo "1) Create  2) Open 3) Delete  0) Exit"
    read -rp "> " k
    case "$k" in 1) create_server;; 2) open_server;; 3) delete_server;; 0) exit;; esac
done












