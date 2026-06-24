package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
)

func main() {
	// Create an HTTP client that communicates over the local Docker Unix socket
	unixClient := http.Client{
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
				return net.Dial("unix", "/var/run/docker.sock")
			},
		},
	}

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

		// Write res.txt
		cfgPath := "/config/res.txt"
		resLine := fmt.Sprintf("%sx%s\n", width, height)
		if err := os.WriteFile(cfgPath, []byte(resLine), 0644); err != nil {
			log.Printf("Failed to write res.txt: %v", err)
			http.Error(w, "Failed to write res.txt", http.StatusInternalServerError)
			return
		}

		// Execute docker restart steam via HTTP POST to the Docker socket
		req, err := http.NewRequest("POST", "http://localhost/containers/steam/restart", nil)
		if err != nil {
			log.Printf("Failed to create request: %v", err)
			http.Error(w, "Internal error", http.StatusInternalServerError)
			return
		}

		resp, err := unixClient.Do(req)
		if err != nil {
			log.Printf("Failed to restart steam container via socket: %v", err)
			http.Error(w, fmt.Sprintf("Failed to restart steam container: %v", err), http.StatusInternalServerError)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			log.Printf("Docker API returned status: %v", resp.StatusCode)
			http.Error(w, fmt.Sprintf("Docker API returned status: %v", resp.StatusCode), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Resolution updated and container restarted!"))
	})

	log.Println("Listening on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}
