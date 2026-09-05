TIMESTAMP := env_var_or_default('TIMESTAMP', `date -u +"%Y%m%d%H%M"`)
COMMIT := env_var_or_default('COMMIT', `git rev-parse --short HEAD 2>/dev/null`)

build-in-container board shield:
	west build \
		-s zmk/app \
		-d build \
		-b {{ board }} -- \
		{{ if shield == "" { "" } else { "-DSHIELD='" + shield +"'" } }} \
		-DZMK_CONFIG=/app/config
	cp build/zephyr/zmk.uf2 "./firmware/{{ TIMESTAMP }}-{{ COMMIT }}-{{ replace(board, '/', '_') }}-{{ shield }}.uf2"

build board shield:
    podman build --tag zmk --file Dockerfile .
    just -n TIMESTAMP={{ TIMESTAMP }} COMMIT={{ COMMIT }} build-in-container "{{ board }}" "{{ shield }}" 2>&1 | \
    podman run --rm -i --name zmk \
    	-v ./firmware:/app/firmware \
    	-v ./config:/app/config:ro \
    	-v ./.git:/.git:ro \
        zmk /bin/bash -ex
    echo {{ COMMIT }}

flash board shield:
    just TIMESTAMP={{ TIMESTAMP }} COMMIT={{ COMMIT }} build "{{ board }}" "{{ shield }}"
    doas env UF2="./firmware/{{ TIMESTAMP }}-{{ COMMIT }}-{{ replace(board, '/', '_') }}-{{ shield }}.uf2" \
    	$(which python3) flash.py
    echo {{ COMMIT }}

totem-right: (build "xiao_ble//zmk" "totem_right")
totem-left: (build "xiao_ble//zmk" "totem_left")
flash-totem-left: (flash "xiao_ble//zmk" "totem_left")
flash-totem-right: (flash "xiao_ble//zmk" "totem_right")
flash-totem-reset: (flash "xiao_ble//zmk" "settings_reset")

klor-left: (build "nice_nano//zmk" "klor_left")
klor-right: (build "nice_nano//zmk" "klor_right")
flash-klor-left: (flash "nice_nano//zmk" "klor_left")
flash-klor-right: (flash "nice_nano//zmk" "klor_right")
alias flash-klor-rigth := flash-klor-right

klor-wired-left: (build "nice_nano//zmk" "klor_wired_left")
klor-wired-right: (build "nice_nano//zmk" "klor_wired_right")
flash-klor-wired-left: (flash "nice_nano//zmk" "klor_wired_left")
flash-klor-wired-right: (flash "nice_nano//zmk" "klor_wired_right")
