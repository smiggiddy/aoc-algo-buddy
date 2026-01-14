package main

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"math/big"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
)

// Algorithm represents an algorithm entry
type Algorithm struct {
	ID               string     `json:"id"`
	Name             string     `json:"name"`
	Category         string     `json:"category"`
	Tags             []string   `json:"tags"`
	Difficulty       string     `json:"difficulty"`
	Description      string     `json:"description"`
	WhenToUse        []string   `json:"whenToUse"`
	PseudoCode       string     `json:"pseudoCode"`
	Complexity       Complexity `json:"complexity"`
	AoCExamples      []string   `json:"aocExamples"`
	Resources        []string   `json:"resources"`
	Examples         []Example  `json:"examples"`
	Prerequisites    []string   `json:"prerequisites,omitempty"`
	KeyInsight       string     `json:"keyInsight,omitempty"`
	CommonPitfalls   []string   `json:"commonPitfalls,omitempty"`
	RelatedAlgos     []string   `json:"relatedAlgos,omitempty"`
	RecognitionHints []string   `json:"recognitionHints,omitempty"`
	Approved         bool       `json:"approved"`
	CreatedAt        time.Time  `json:"createdAt"`
	SubmittedBy      string     `json:"submittedBy,omitempty"`
}

type Complexity struct {
	Time  string `json:"time"`
	Space string `json:"space"`
}

// Example with visual representation
type Example struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	Input       string   `json:"input"`
	Output      string   `json:"output"`
	Steps       []Step   `json:"steps"`
	Visual      string   `json:"visual"` // ASCII art or diagram
}

type Step struct {
	Description string `json:"description"`
	State       string `json:"state"` // Visual state at this step
}

// Submission represents a pending algorithm submission
type Submission struct {
	ID          string    `json:"id"`
	Algorithm   Algorithm `json:"algorithm"`
	SubmittedAt time.Time `json:"submittedAt"`
	Status      string    `json:"status"` // pending, approved, rejected
	ReviewedAt  *time.Time `json:"reviewedAt,omitempty"`
}

// CaptchaChallenge for anti-spam
type CaptchaChallenge struct {
	ID        string    `json:"id"`
	Question  string    `json:"question"`
	Answer    int       `json:"answer"`
	ExpiresAt time.Time `json:"expiresAt"`
}

// Database holds all data with file persistence
type Database struct {
	mu          sync.RWMutex
	Algorithms  []Algorithm         `json:"algorithms"`
	Submissions []Submission        `json:"submissions"`
	dataFile    string
	captchas    map[string]CaptchaChallenge
	captchaMu   sync.RWMutex
}

// RateLimiter provides simple rate limiting per IP
type RateLimiter struct {
	mu       sync.Mutex
	requests map[string][]time.Time
	limit    int           // max requests
	window   time.Duration // time window
}

func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	rl := &RateLimiter{
		requests: make(map[string][]time.Time),
		limit:    limit,
		window:   window,
	}
	// Cleanup old entries periodically
	go func() {
		for {
			time.Sleep(window)
			rl.cleanup()
		}
	}()
	return rl
}

func (rl *RateLimiter) cleanup() {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	now := time.Now()
	for ip, times := range rl.requests {
		var valid []time.Time
		for _, t := range times {
			if now.Sub(t) < rl.window {
				valid = append(valid, t)
			}
		}
		if len(valid) == 0 {
			delete(rl.requests, ip)
		} else {
			rl.requests[ip] = valid
		}
	}
}

func (rl *RateLimiter) Allow(ip string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	now := time.Now()
	times := rl.requests[ip]

	// Filter to only requests within the window
	var valid []time.Time
	for _, t := range times {
		if now.Sub(t) < rl.window {
			valid = append(valid, t)
		}
	}

	if len(valid) >= rl.limit {
		return false
	}

	rl.requests[ip] = append(valid, now)
	return true
}

// Rate limiters for different endpoints
var (
	submitLimiter = NewRateLimiter(5, time.Minute)       // 5 submissions per minute
	adminLimiter  = NewRateLimiter(10, time.Minute)      // 10 admin attempts per minute
	apiLimiter    = NewRateLimiter(100, time.Minute)     // 100 API requests per minute
)

// Maximum sizes for input validation
const (
	maxNameLength        = 200
	maxDescriptionLength = 5000
	maxPseudoCodeLength  = 50000
	maxFieldLength       = 1000
	maxArrayLength       = 50
)

var db *Database

// Admin credentials (set via environment variables)
var adminUser = getEnv("ADMIN_USER", "admin")
var adminPass = getEnv("ADMIN_PASS", "changeme")
var dataDir = getEnv("DATA_DIR", "")

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func init() {
	dataFile := "data.json"
	if dataDir != "" {
		dataFile = filepath.Join(dataDir, "data.json")
	}

	db = &Database{
		dataFile: dataFile,
		captchas: make(map[string]CaptchaChallenge),
	}

	// Check if reseed is requested via env var
	reseed := os.Getenv("RESEED") == "true" || os.Getenv("RESEED") == "1"

	if reseed {
		log.Println("RESEED=true: Rebuilding database from seed_data.json")
		loadFromSeed(db)
	} else if err := db.Load(); err != nil {
		log.Printf("No existing data.json, loading from seed_data.json: %v", err)
		loadFromSeed(db)
	} else {
		log.Printf("Loaded %d algorithms from data.json", len(db.Algorithms))
	}

	// Clean up expired captchas periodically
	go func() {
		for {
			time.Sleep(5 * time.Minute)
			db.cleanExpiredCaptchas()
		}
	}()
}

func loadFromSeed(d *Database) {
	seedData, err := os.ReadFile("seed_data.json")
	if err != nil {
		log.Fatalf("Failed to read seed_data.json: %v", err)
	}
	var seedAlgos []Algorithm
	if err := json.Unmarshal(seedData, &seedAlgos); err != nil {
		log.Fatalf("Failed to parse seed_data.json: %v", err)
	}
	d.Algorithms = seedAlgos
	d.Submissions = []Submission{} // Reset submissions on reseed
	log.Printf("Loaded %d algorithms from seed_data.json", len(seedAlgos))

	// Mark all seeded algorithms as approved
	for i := range d.Algorithms {
		d.Algorithms[i].Approved = true
		d.Algorithms[i].CreatedAt = time.Now()
	}
	d.Save()
}

func (d *Database) Load() error {
	d.mu.Lock()
	defer d.mu.Unlock()

	data, err := os.ReadFile(d.dataFile)
	if err != nil {
		return err
	}

	return json.Unmarshal(data, d)
}

func (d *Database) Save() error {
	d.mu.Lock()
	defer d.mu.Unlock()

	data, err := json.MarshalIndent(d, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(d.dataFile, data, 0644)
}

func (d *Database) GetApprovedAlgorithms() []Algorithm {
	d.mu.RLock()
	defer d.mu.RUnlock()

	approved := make([]Algorithm, 0)
	for _, algo := range d.Algorithms {
		if algo.Approved {
			approved = append(approved, algo)
		}
	}
	return approved
}

func (d *Database) GetAlgorithmByID(id string) *Algorithm {
	d.mu.RLock()
	defer d.mu.RUnlock()

	for i := range d.Algorithms {
		if d.Algorithms[i].ID == id && d.Algorithms[i].Approved {
			return &d.Algorithms[i]
		}
	}
	return nil
}

func (d *Database) AddSubmission(algo Algorithm, submittedBy string) string {
	d.mu.Lock()
	defer d.mu.Unlock()

	id := generateID()
	algo.Approved = false
	algo.CreatedAt = time.Now()
	algo.SubmittedBy = submittedBy

	submission := Submission{
		ID:          id,
		Algorithm:   algo,
		SubmittedAt: time.Now(),
		Status:      "pending",
	}

	d.Submissions = append(d.Submissions, submission)
	d.saveUnlocked()
	return id
}

func (d *Database) GetPendingSubmissions() []Submission {
	d.mu.RLock()
	defer d.mu.RUnlock()

	pending := make([]Submission, 0)
	for _, sub := range d.Submissions {
		if sub.Status == "pending" {
			pending = append(pending, sub)
		}
	}
	return pending
}

func (d *Database) ApproveSubmission(id string) error {
	d.mu.Lock()
	defer d.mu.Unlock()

	for i := range d.Submissions {
		if d.Submissions[i].ID == id && d.Submissions[i].Status == "pending" {
			now := time.Now()
			d.Submissions[i].Status = "approved"
			d.Submissions[i].ReviewedAt = &now

			algo := d.Submissions[i].Algorithm
			algo.Approved = true
			algo.ID = generateSlug(algo.Name)
			d.Algorithms = append(d.Algorithms, algo)

			return d.saveUnlocked()
		}
	}
	return fmt.Errorf("submission not found")
}

func (d *Database) RejectSubmission(id string) error {
	d.mu.Lock()
	defer d.mu.Unlock()

	for i := range d.Submissions {
		if d.Submissions[i].ID == id && d.Submissions[i].Status == "pending" {
			now := time.Now()
			d.Submissions[i].Status = "rejected"
			d.Submissions[i].ReviewedAt = &now
			return d.saveUnlocked()
		}
	}
	return fmt.Errorf("submission not found")
}

func (d *Database) saveUnlocked() error {
	data, err := json.MarshalIndent(d, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(d.dataFile, data, 0644)
}

// Captcha methods
func (d *Database) CreateCaptcha() CaptchaChallenge {
	d.captchaMu.Lock()
	defer d.captchaMu.Unlock()

	a, _ := rand.Int(rand.Reader, big.NewInt(20))
	b, _ := rand.Int(rand.Reader, big.NewInt(20))
	num1 := int(a.Int64()) + 1
	num2 := int(b.Int64()) + 1

	captcha := CaptchaChallenge{
		ID:        generateID(),
		Question:  fmt.Sprintf("What is %d + %d?", num1, num2),
		Answer:    num1 + num2,
		ExpiresAt: time.Now().Add(10 * time.Minute),
	}

	d.captchas[captcha.ID] = captcha
	return captcha
}

func (d *Database) ValidateCaptcha(id string, answer int) bool {
	d.captchaMu.Lock()
	defer d.captchaMu.Unlock()

	captcha, exists := d.captchas[id]
	if !exists {
		return false
	}

	delete(d.captchas, id) // One-time use

	if time.Now().After(captcha.ExpiresAt) {
		return false
	}

	return captcha.Answer == answer
}

func (d *Database) cleanExpiredCaptchas() {
	d.captchaMu.Lock()
	defer d.captchaMu.Unlock()

	now := time.Now()
	for id, captcha := range d.captchas {
		if now.After(captcha.ExpiresAt) {
			delete(d.captchas, id)
		}
	}
}

func main() {
	mux := http.NewServeMux()

	// Public API routes
	mux.HandleFunc("/api/algorithms", handleAlgorithms)
	mux.HandleFunc("/api/algorithms/", handleAlgorithmByID)
	mux.HandleFunc("/api/categories", handleCategories)
	mux.HandleFunc("/api/tags", handleTags)

	// Submission routes
	mux.HandleFunc("/api/captcha", handleCaptcha)
	mux.HandleFunc("/api/submit", handleSubmit)

	// Admin routes (protected)
	mux.HandleFunc("/api/admin/submissions", adminAuth(handleAdminSubmissions))
	mux.HandleFunc("/api/admin/approve/", adminAuth(handleAdminApprove))
	mux.HandleFunc("/api/admin/reject/", adminAuth(handleAdminReject))

	// Serve static files for production
	mux.HandleFunc("/", handleStatic)

	// Middleware chain: logging -> security headers -> rate limit -> CORS -> handler
	handler := loggingMiddleware(securityHeadersMiddleware(rateLimitMiddleware(apiLimiter)(corsMiddleware(mux))))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if dataDir != "" {
		log.Printf("Data directory: %s", dataDir)
	}

	// Security warning for default credentials
	if adminPass == "changeme" {
		log.Println("WARNING: Using default admin password! Set ADMIN_PASS environment variable for production.")
	}

	log.Fatal(http.ListenAndServe(":"+port, handler))
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	status int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.status = code
	rw.ResponseWriter.WriteHeader(code)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		wrapped := &responseWriter{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(wrapped, r)

		ip := getClientIP(r)
		userAgent := r.Header.Get("User-Agent")
		cfRay := r.Header.Get("CF-Ray") // Cloudflare Ray ID for request tracing

		// Enhanced logging with optional Cloudflare tracing
		if cfRay != "" {
			log.Printf("%s %s %s %d %s [ray:%s] [ua:%s]", ip, r.Method, r.URL.Path, wrapped.status, time.Since(start), cfRay, truncateUA(userAgent))
		} else {
			log.Printf("%s %s %s %d %s [ua:%s]", ip, r.Method, r.URL.Path, wrapped.status, time.Since(start), truncateUA(userAgent))
		}
	})
}

// truncateUA truncates User-Agent to a reasonable length for logging
func truncateUA(ua string) string {
	if len(ua) > 100 {
		return ua[:100] + "..."
	}
	return ua
}

func securityHeadersMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Security headers
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")
		w.Header().Set("Permissions-Policy", "geolocation=(), microphone=(), camera=()")

		// Content Security Policy - adjust as needed for your frontend
		w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'")

		next.ServeHTTP(w, r)
	})
}

func corsMiddleware(next http.Handler) http.Handler {
	// Get allowed origin from environment, default to * for development
	allowedOrigin := getEnv("CORS_ORIGIN", "*")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func rateLimitMiddleware(limiter *RateLimiter) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := getClientIP(r)

			if !limiter.Allow(ip) {
				http.Error(w, "Rate limit exceeded. Please try again later.", http.StatusTooManyRequests)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// clientIPHeaders defines the priority order for client IP detection.
// Headers are checked in order, with the first non-empty value used.
var clientIPHeaders = []string{
	"CF-Connecting-IP", // Cloudflare
	"True-Client-IP",   // Cloudflare Enterprise / Akamai
	"X-Real-IP",        // Nginx proxy
	"X-Forwarded-For",  // Standard proxy header (may contain comma-separated list)
}

// getClientIP extracts the client IP from the request, checking various
// proxy headers in priority order before falling back to RemoteAddr.
func getClientIP(r *http.Request) string {
	for _, header := range clientIPHeaders {
		if ip := r.Header.Get(header); ip != "" {
			// X-Forwarded-For can contain multiple IPs; take the first (client) IP
			if idx := strings.Index(ip, ","); idx != -1 {
				ip = strings.TrimSpace(ip[:idx])
			}
			return strings.TrimSpace(ip)
		}
	}

	// Fallback to RemoteAddr, stripping port if present
	ip := r.RemoteAddr
	if idx := strings.LastIndex(ip, ":"); idx != -1 {
		// Check if this is IPv6 (contains multiple colons)
		if strings.Count(ip, ":") > 1 {
			// IPv6 address - check for bracket notation [::1]:port
			if bracketIdx := strings.LastIndex(ip, "]"); bracketIdx != -1 {
				ip = ip[1:bracketIdx] // Remove brackets
			}
		} else {
			ip = ip[:idx] // IPv4 - just remove port
		}
	}
	return ip
}

func adminAuth(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Rate limit admin login attempts to prevent brute force
		ip := getClientIP(r)
		if !adminLimiter.Allow(ip) {
			http.Error(w, "Too many login attempts. Please try again later.", http.StatusTooManyRequests)
			return
		}

		user, pass, ok := r.BasicAuth()
		if !ok {
			w.Header().Set("WWW-Authenticate", `Basic realm="Admin"`)
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		userHash := sha256.Sum256([]byte(user))
		passHash := sha256.Sum256([]byte(pass))
		expectedUserHash := sha256.Sum256([]byte(adminUser))
		expectedPassHash := sha256.Sum256([]byte(adminPass))

		userMatch := subtle.ConstantTimeCompare(userHash[:], expectedUserHash[:]) == 1
		passMatch := subtle.ConstantTimeCompare(passHash[:], expectedPassHash[:]) == 1

		if !userMatch || !passMatch {
			w.Header().Set("WWW-Authenticate", `Basic realm="Admin"`)
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}

		next(w, r)
	}
}

func handleAlgorithms(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	algorithms := db.GetApprovedAlgorithms()

	query := r.URL.Query()
	category := query.Get("category")
	tag := query.Get("tag")
	search := strings.ToLower(query.Get("search"))
	difficulty := query.Get("difficulty")

	filtered := make([]Algorithm, 0)
	for _, algo := range algorithms {
		if category != "" && algo.Category != category {
			continue
		}
		if difficulty != "" && algo.Difficulty != difficulty {
			continue
		}
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

	algo := db.GetAlgorithmByID(id)
	if algo == nil {
		http.Error(w, "Algorithm not found", http.StatusNotFound)
		return
	}

	respondJSON(w, algo)
}

func handleCategories(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	algorithms := db.GetApprovedAlgorithms()
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

	algorithms := db.GetApprovedAlgorithms()
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

func handleCaptcha(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	captcha := db.CreateCaptcha()
	respondJSON(w, map[string]string{
		"id":       captcha.ID,
		"question": captcha.Question,
	})
}

type SubmitRequest struct {
	CaptchaID     string    `json:"captchaId"`
	CaptchaAnswer int       `json:"captchaAnswer"`
	SubmittedBy   string    `json:"submittedBy"`
	Algorithm     Algorithm `json:"algorithm"`
}

func handleSubmit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Rate limit submissions
	ip := getClientIP(r)
	if !submitLimiter.Allow(ip) {
		http.Error(w, "Too many submissions. Please try again later.", http.StatusTooManyRequests)
		return
	}

	// Limit request body size (1MB max)
	r.Body = http.MaxBytesReader(w, r.Body, 1<<20)

	var req SubmitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate captcha
	if !db.ValidateCaptcha(req.CaptchaID, req.CaptchaAnswer) {
		http.Error(w, "Invalid or expired captcha", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if req.Algorithm.Name == "" || req.Algorithm.Category == "" ||
		req.Algorithm.Description == "" || req.Algorithm.PseudoCode == "" {
		http.Error(w, "Missing required fields", http.StatusBadRequest)
		return
	}

	// Validate field lengths to prevent abuse
	if len(req.Algorithm.Name) > maxNameLength {
		http.Error(w, "Name exceeds maximum length", http.StatusBadRequest)
		return
	}
	if len(req.Algorithm.Description) > maxDescriptionLength {
		http.Error(w, "Description exceeds maximum length", http.StatusBadRequest)
		return
	}
	if len(req.Algorithm.PseudoCode) > maxPseudoCodeLength {
		http.Error(w, "Pseudo code exceeds maximum length", http.StatusBadRequest)
		return
	}
	if len(req.Algorithm.Tags) > maxArrayLength {
		http.Error(w, "Too many tags", http.StatusBadRequest)
		return
	}
	if len(req.Algorithm.WhenToUse) > maxArrayLength {
		http.Error(w, "Too many 'when to use' items", http.StatusBadRequest)
		return
	}

	submissionID := db.AddSubmission(req.Algorithm, req.SubmittedBy)

	respondJSON(w, map[string]string{
		"message":      "Algorithm submitted for review",
		"submissionId": submissionID,
	})
}

func handleAdminSubmissions(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	submissions := db.GetPendingSubmissions()
	respondJSON(w, submissions)
}

func handleAdminApprove(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/api/admin/approve/")
	if id == "" {
		http.Error(w, "Submission ID required", http.StatusBadRequest)
		return
	}

	if err := db.ApproveSubmission(id); err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	respondJSON(w, map[string]string{"message": "Submission approved"})
}

func handleAdminReject(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/api/admin/reject/")
	if id == "" {
		http.Error(w, "Submission ID required", http.StatusBadRequest)
		return
	}

	if err := db.RejectSubmission(id); err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	respondJSON(w, map[string]string{"message": "Submission rejected"})
}

func handleStatic(w http.ResponseWriter, r *http.Request) {
	if _, err := os.Stat("./static"); os.IsNotExist(err) {
		http.Error(w, "Frontend not built", http.StatusNotFound)
		return
	}

	fs := http.FileServer(http.Dir("./static"))
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

func generateID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

func generateSlug(name string) string {
	reg := regexp.MustCompile(`[^a-zA-Z0-9]+`)
	slug := reg.ReplaceAllString(strings.ToLower(name), "-")
	slug = strings.Trim(slug, "-")
	return slug
}
