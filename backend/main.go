package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strings"
)

// Algorithm represents an algorithm entry
type Algorithm struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Category    string   `json:"category"`
	Tags        []string `json:"tags"`
	Difficulty  string   `json:"difficulty"`
	Description string   `json:"description"`
	WhenToUse   []string `json:"whenToUse"`
	PseudoCode  string   `json:"pseudoCode"`
	Complexity  struct {
		Time  string `json:"time"`
		Space string `json:"space"`
	} `json:"complexity"`
	AoCExamples []string `json:"aocExamples"`
	Resources   []string `json:"resources"`
}

var algorithms []Algorithm

func init() {
	algorithms = loadAlgorithms()
}

func main() {
	mux := http.NewServeMux()

	// API routes
	mux.HandleFunc("/api/algorithms", handleAlgorithms)
	mux.HandleFunc("/api/algorithms/", handleAlgorithmByID)
	mux.HandleFunc("/api/categories", handleCategories)
	mux.HandleFunc("/api/tags", handleTags)

	// Serve static files for production
	mux.HandleFunc("/", handleStatic)

	// CORS middleware
	handler := corsMiddleware(mux)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, handler))
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func handleAlgorithms(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	query := r.URL.Query()
	category := query.Get("category")
	tag := query.Get("tag")
	search := strings.ToLower(query.Get("search"))
	difficulty := query.Get("difficulty")

	filtered := make([]Algorithm, 0)
	for _, algo := range algorithms {
		// Filter by category
		if category != "" && algo.Category != category {
			continue
		}

		// Filter by difficulty
		if difficulty != "" && algo.Difficulty != difficulty {
			continue
		}

		// Filter by tag
		if tag != "" {
			hasTag := false
			for _, t := range algo.Tags {
				if t == tag {
					hasTag = true
					break
				}
			}
			if !hasTag {
				continue
			}
		}

		// Filter by search term
		if search != "" {
			nameMatch := strings.Contains(strings.ToLower(algo.Name), search)
			descMatch := strings.Contains(strings.ToLower(algo.Description), search)
			tagMatch := false
			for _, t := range algo.Tags {
				if strings.Contains(strings.ToLower(t), search) {
					tagMatch = true
					break
				}
			}
			if !nameMatch && !descMatch && !tagMatch {
				continue
			}
		}

		filtered = append(filtered, algo)
	}

	respondJSON(w, filtered)
}

func handleAlgorithmByID(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/api/algorithms/")
	if id == "" {
		http.Error(w, "Algorithm ID required", http.StatusBadRequest)
		return
	}

	for _, algo := range algorithms {
		if algo.ID == id {
			respondJSON(w, algo)
			return
		}
	}

	http.Error(w, "Algorithm not found", http.StatusNotFound)
}

func handleCategories(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	categorySet := make(map[string]bool)
	for _, algo := range algorithms {
		categorySet[algo.Category] = true
	}

	categories := make([]string, 0, len(categorySet))
	for cat := range categorySet {
		categories = append(categories, cat)
	}

	respondJSON(w, categories)
}

func handleTags(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tagSet := make(map[string]bool)
	for _, algo := range algorithms {
		for _, tag := range algo.Tags {
			tagSet[tag] = true
		}
	}

	tags := make([]string, 0, len(tagSet))
	for tag := range tagSet {
		tags = append(tags, tag)
	}

	respondJSON(w, tags)
}

func handleStatic(w http.ResponseWriter, r *http.Request) {
	// Check if static directory exists
	if _, err := os.Stat("./static"); os.IsNotExist(err) {
		http.Error(w, "Frontend not built", http.StatusNotFound)
		return
	}

	// Serve static files
	fs := http.FileServer(http.Dir("./static"))

	// For SPA routing, serve index.html for non-file requests
	path := r.URL.Path
	if path != "/" && !strings.Contains(path, ".") {
		http.ServeFile(w, r, "./static/index.html")
		return
	}

	fs.ServeHTTP(w, r)
}

func respondJSON(w http.ResponseWriter, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}
