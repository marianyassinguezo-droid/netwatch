#!/bin/bash
# NetWatch : détecte les changements sur un réseau

CONFIG="config.conf"

if ! command -v nmap > /dev/null; then
    echo "Erreur : nmap n'est pas installé." >&2
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "Erreur : fichier de config introuvable : $CONFIG" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG"

DATE=$(date +%Y-%m-%d_%H-%M)
DOSSIER="$SORTIE/$DATE"
mkdir -p "$DOSSIER"
LOG="$SORTIE/netwatch.log"

echo "Scan de $RESEAU en cours..."
echo "[$DATE] Scan de $RESEAU" >> "$LOG"

nmap -sn "$RESEAU" -oG - | awk '/Up$/{print $2}' | sort > "$DOSSIER/hotes.txt"
echo "Machines trouvées : $(wc -l < "$DOSSIER/hotes.txt")"

PRECEDENT=""
for D in "$SORTIE"/20*/; do
    [ -d "$D" ] || continue
    D="${D%/}"
    if [ "$D" != "$DOSSIER" ]; then
        PRECEDENT="$D"
    fi
done

if [ -z "$PRECEDENT" ]; then
    echo "Premier scan : rien à comparer."
    echo "[$DATE] Premier scan, référence créée" >> "$LOG"
    exit 0
fi

NOUVELLES=$(comm -13 "$PRECEDENT/hotes.txt" "$DOSSIER/hotes.txt")
DISPARUES=$(comm -23 "$PRECEDENT/hotes.txt" "$DOSSIER/hotes.txt")

RAPPORT="$DOSSIER/rapport.md"
{
    echo "# Rapport NetWatch - $DATE"
    echo "## Nouvelles machines"
    echo "${NOUVELLES:-Aucune}"
    echo "## Machines disparues"
    echo "${DISPARUES:-Aucune}"
} > "$RAPPORT"

cat "$RAPPORT"

if [ -n "$NOUVELLES" ] || [ -n "$DISPARUES" ]; then
    echo "[$DATE] ALERTE : changement détecté" >> "$LOG"
else
    echo "[$DATE] Aucun changement" >> "$LOG"
fi
