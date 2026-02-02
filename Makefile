rules:
	echo 'KERNEL=="uinput", MODE="0666", GROUP="input" KERNEL=="event*", MODE="0666", GROUP="input"' | sudo tee /etc/udev/rules.d/99-steam-input.rules

start:
	docker compose up
