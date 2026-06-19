DC=docker compose
DCRP=$(DC) run --rm --service-ports --use-aliases
DCE=$(DC) exec

rules:
	echo 'KERNEL=="uinput", MODE="0666", GROUP="input" KERNEL=="event*", MODE="0666", GROUP="input"' | sudo tee /etc/udev/rules.d/99-steam-input.rules

setup:
	@echo "Creating compose.override.yml from example..."
	@cp compose.override.yml.example compose.override.yml
	@sed -i "s/PUID=1000/PUID=$$(id -u)/g" compose.override.yml
	@sed -i "s/PGID=1000/PGID=$$(id -g)/g" compose.override.yml
	@sed -i "s/RENDER_GID=989/RENDER_GID=$$(getent group render | cut -d: -f3)/g" compose.override.yml
	@sed -i "s/INPUT_GID=993/INPUT_GID=$$(getent group input | cut -d: -f3)/g" compose.override.yml
	@echo "Setup complete! Created compose.override.yml with this system's IDs."

start:
	docker compose up -d

sway:
	$(DCRP) steam sway

vnc:
	$(DCE) steam wayvnc 0.0.0.0
