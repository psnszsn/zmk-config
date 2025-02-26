TIMESTAMP := `date -u +"%Y%m%d%H%M"`
COMMIT := `git rev-parse --short HEAD 2>/dev/null`

build-in-container board shield:
	west build \
		-s {{ if board =~ "adv360pro" { "zmk-adv" } else { "zmk" } }}/app \
		-d build \
		-b {{ board }} -- \
		{{ if shield == "" { "" } else { "-DSHIELD='" + shield +"'" } }} \
		-DZMK_CONFIG=/app/config
	cp build/zephyr/zmk.uf2 "./firmware/{{ TIMESTAMP }}-{{ COMMIT }}-{{ board }}-{{ shield }}.uf2"

build board shield:
    podman build --tag zmk --file Dockerfile .
    just -n build-in-container "{{ board }}" "{{ shield }}" 2>&1 | \
    podman run --rm -i --name zmk \
    	-v ./firmware:/app/firmware \
    	-v ./config:/app/config:ro \
    	-v ./.git:/.git:ro \
    	zmk /bin/bash -x
    echo {{ COMMIT }}

flash board shield:
    just build "{{ board }}" "{{ shield }}"
    doas env UF2="./firmware/{{ TIMESTAMP }}-{{ COMMIT }}-{{ board }}-{{ shield }}.uf2" \
    	python3 flash.py
    echo {{ COMMIT }}

totem-right: (build "seeeduino_xiao_ble" "totem_right")
totem-left: (build "seeeduino_xiao_ble" "totem_left")
flash-totem-left: (flash "seeeduino_xiao_ble" "totem_left")
flash-totem-right: (flash "seeeduino_xiao_ble" "totem_right")
flash-totem-reset: (flash "seeeduino_xiao_ble" "settings_reset")

adv360pro-left: (build "adv360pro_left" "")
flash-adv360pro-left: (flash "adv360pro_left" "")
flash-adv360pro-right: (flash "adv360pro_right" "")

sofle-left: (build "eyelash_sofle_left" "nice_view")
flash-sofle-left: (flash "eyelash_sofle_left" "nice_view")
flash-sofle-right: (flash "eyelash_sofle_right" "nice_view")
flash-sofle-reset: (flash "eyelash_sofle_left" "settings_reset")
