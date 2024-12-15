TIMESTAMP := `date -u +"%Y%m%d%H%M"`
COMMIT := `git rev-parse --short HEAD 2>/dev/null`


build-in-container board shield:
	west build -s zmk/app -d build -b {{board}} -- -DSHIELD={{shield}} -DZMK_CONFIG=/app/config
	cp build/zephyr/zmk.uf2 "./firmware/{{TIMESTAMP}}-{{COMMIT}}-{{board}}-{{shield}}.uf2"

build board shield:
	podman build --tag zmk --file Dockerfile .
	just -n build-in-container {{board}} {{shield}} 2>&1 | \
	podman run --rm -i --name zmk \
		-v ./firmware:/app/firmware \
		-v ./config:/app/config:ro \
		-v ./.git:/.git:ro \
		zmk /bin/bash -x
	echo {{COMMIT}}

flash board shield:
	just build {{board}} {{shield}}
	doas env UF2="./firmware/{{TIMESTAMP}}-{{COMMIT}}-{{board}}-{{shield}}.uf2" \
		python3 flash.py

totem-right: (build "seeeduino_xiao_ble" "totem_right")
totem-left: (build "seeeduino_xiao_ble" "totem_left")
flash-totem-left: (flash "seeeduino_xiao_ble" "totem_left")
