package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strings"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		http.ServeFile(w, r, "index.html")
	})

	http.HandleFunc("/set", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		res := r.FormValue("resolution")
		if res == "" {
			http.Error(w, "Missing resolution", http.StatusBadRequest)
			return
		}

		parts := strings.Split(res, "x")
		if len(parts) != 2 {
			http.Error(w, "Invalid resolution format", http.StatusBadRequest)
			return
		}

		width, height := parts[0], parts[1]

		// Execute docker compose up -d steam
		cmd := exec.Command("docker", "compose", "up", "-d", "steam")
		cmd.Dir = "/project"
		
		// Pass inline environment variables for dynamic compose interpolation
		cmd.Env = append(os.Environ(), 
			fmt.Sprintf("GAMESCOPE_W=%s", width),
			fmt.Sprintf("GAMESCOPE_H=%s", height),
			"GAMESCOPE_R=60",
		)

		output, err := cmd.CombinedOutput()
		if err != nil {
			log.Printf("Failed to restart container: %v\nOutput: %s", err, output)
			http.Error(w, fmt.Sprintf("Failed to restart steam container: %v", err), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Container restarted successfully!"))
	})

	log.Println("Listening on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
