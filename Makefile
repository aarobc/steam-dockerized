DC=docker compose
DCRP=$(DC) run --rm --service-ports --use-aliases
DCE=$(DC) exec

rules:
	echo 'KERNEL=="uinput", MODE="0666", GROUP="input" KERNEL=="event*", MODE="0666", GROUP="input"' | sudo tee /etc/udev/rules.d/99-steam-input.rules

start:
	docker compose up -d

sway:
	$(DCRP) steam sway

vnc:
	$(DCE) steam wayvnc 0.0.0.0
