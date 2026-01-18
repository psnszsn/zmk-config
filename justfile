TIMESTAMP := env_var_or_default('TIMESTAMP', `date -u +"%Y%m%d%H%M"`)
COMMIT := env_var_or_default('COMMIT', `git rev-parse --short HEAD 2>/dev/null`)

build-in-container board shield:
	west build \
		-s zmk/app \
		-d build \
		-b {{ board }} -- \
		{{ if shield == "" { "" } else { "-DSHIELD='" + shield +"'" } }} \
		-DZMK_CONFIG=/app/config
	cp build/zephyr/zmk.uf2 "./firmware/{{ TIMESTAMP }}-{{ COMMIT }}-{{ board }}-{{ shield }}.uf2"

build board shield:
    nerdctl build --tag zmk --file Dockerfile .
    just -n TIMESTAMP={{ TIMESTAMP }} COMMIT={{ COMMIT }} build-in-container "{{ board }}" "{{ shield }}" 2>&1 | \
    nerdctl run --rm -i --name zmk \
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

totem-right: (build "xiao_ble" "totem_right")
totem-left: (build "xiao_ble" "totem_left")
flash-totem-left: (flash "xiao_ble" "totem_left")
flash-totem-right: (flash "xiao_ble" "totem_right")
flash-totem-reset: (flash "xiao_ble" "settings_reset")

sofle-left: (build "eyelash_sofle_left" "nice_view")
flash-sofle-left: (flash "eyelash_sofle_left" "nice_view")
flash-sofle-right: (flash "eyelash_sofle_right" "nice_view")
flash-sofle-reset: (flash "eyelash_sofle_left" "settings_reset")

klor-left: (build "nice_nano" "klor_left")
flash-klor-left: (flash "nice_nano" "klor_left")
flash-klor-rigth: (flash "nice_nano" "klor_right")
