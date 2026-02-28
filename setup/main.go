package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ── Styles ────────────────────────────────────────────────────────────────────

var (
	titleStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("12"))
	selectedStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("10")).Bold(true)
	dimStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("8"))
	successStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("10"))
	stepStyle     = lipgloss.NewStyle().Foreground(lipgloss.Color("14"))
	checkStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("10"))
	crossStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("9"))
)

// ── Configs ───────────────────────────────────────────────────────────────────

type nixConfig struct {
	name        string
	flakeTarget string
	description string
}

var configs = []nixConfig{
	{
		name:        "shell",
		flakeTarget: "yanklio-shell",
		description: "Terminal tools: zsh, neovim, tmux, fastfetch",
	},
	{
		name:        "desktop",
		flakeTarget: "yanklio-desktop",
		description: "Shell + GUI apps: alacritty, zed",
	},
}

// ── Stages ────────────────────────────────────────────────────────────────────

type stage int

const (
	stagePick stage = iota
	stageRunning
	stageDone
)

// ── Messages ──────────────────────────────────────────────────────────────────

type stepMsg struct{ text string }
type doneMsg struct{ err error }

// ── Model ─────────────────────────────────────────────────────────────────────

type model struct {
	stage    stage
	cursor   int
	chosen   nixConfig
	spinner  spinner.Model
	steps    []string
	finalErr error
	ch       <-chan tea.Msg
}

func initialModel() model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color("12"))
	return model{spinner: s}
}

// ── Init ──────────────────────────────────────────────────────────────────────

func (m model) Init() tea.Cmd {
	return nil
}

// ── Update ────────────────────────────────────────────────────────────────────

// drainCh reads the next message from the channel as a Cmd.
func drainCh(ch <-chan tea.Msg) tea.Cmd {
	return func() tea.Msg {
		return <-ch
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch m.stage {

	case stagePick:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "ctrl+c", "q":
				return m, tea.Quit
			case "up", "k":
				if m.cursor > 0 {
					m.cursor--
				}
			case "down", "j":
				if m.cursor < len(configs)-1 {
					m.cursor++
				}
			case "enter", " ":
				m.chosen = configs[m.cursor]
				m.stage = stageRunning
				ch := startSetup(m.chosen)
				m.ch = ch
				return m, tea.Batch(m.spinner.Tick, drainCh(ch))
			}
		}

	case stageRunning:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "ctrl+c" {
				return m, tea.Quit
			}
		case spinner.TickMsg:
			var cmd tea.Cmd
			m.spinner, cmd = m.spinner.Update(msg)
			return m, cmd
		case stepMsg:
			m.steps = append(m.steps, msg.text)
			return m, tea.Batch(m.spinner.Tick, drainCh(m.ch))
		case doneMsg:
			m.finalErr = msg.err
			m.stage = stageDone
			return m, tea.Quit
		}

	case stageDone:
		return m, tea.Quit
	}

	return m, nil
}

// ── View ──────────────────────────────────────────────────────────────────────

func (m model) View() string {
	var b strings.Builder

	b.WriteString(titleStyle.Render("  nix setup") + "\n\n")

	switch m.stage {

	case stagePick:
		b.WriteString("Choose a Home Manager config:\n\n")
		for i, c := range configs {
			cursor := "  "
			name := fmt.Sprintf("%-10s", c.name)
			desc := dimStyle.Render(c.description)
			if i == m.cursor {
				cursor = selectedStyle.Render("▶ ")
				name = selectedStyle.Render(name)
			}
			b.WriteString(cursor + name + " " + desc + "\n")
		}
		b.WriteString("\n" + dimStyle.Render("↑/↓  navigate   enter  select   q  quit") + "\n")

	case stageRunning:
		for _, s := range m.steps {
			b.WriteString(checkStyle.Render("✓ ") + s + "\n")
		}
		b.WriteString(m.spinner.View() + " " + stepStyle.Render("running…") + "\n")

	case stageDone:
		for _, s := range m.steps {
			b.WriteString(checkStyle.Render("✓ ") + s + "\n")
		}
		b.WriteString("\n")
		if m.finalErr != nil {
			b.WriteString(crossStyle.Render("✗ failed: ") + m.finalErr.Error() + "\n")
		} else {
			b.WriteString(successStyle.Render("✓ all done! home-manager config applied.") + "\n")
		}
	}

	return b.String()
}

// ── Setup runner ──────────────────────────────────────────────────────────────

// startSetup launches all steps in a goroutine and returns a channel that
// emits stepMsg for each completed step, then doneMsg when finished (or on error).
func startSetup(cfg nixConfig) <-chan tea.Msg {
	type step struct {
		label string
		fn    func() error
	}

	steps := []step{
		{"checking for nix", ensureNix},
		{"ensuring nix-command & flakes enabled", ensureFlakeSupport},
		{"linking dotfiles to ~/.config/home-manager", linkConfig},
		{"ensuring home-manager available", ensureHomeManager},
		{fmt.Sprintf("applying %s config", cfg.flakeTarget), func() error {
			return applyConfig(cfg)
		}},
	}

	ch := make(chan tea.Msg, len(steps)+1)

	go func() {
		for _, s := range steps {
			if err := s.fn(); err != nil {
				ch <- doneMsg{err: fmt.Errorf("%s: %w", s.label, err)}
				return
			}
			ch <- stepMsg{text: s.label}
		}
		ch <- doneMsg{}
	}()

	return ch
}

// ── Step implementations ──────────────────────────────────────────────────────

func ensureNix() error {
	if _, err := exec.LookPath("nix"); err == nil {
		return nil
	}
	cmd := exec.Command("bash", "-c",
		`curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm`)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

func ensureFlakeSupport() error {
	// Determinate Systems enables flakes by default.
	// For official installer: write to user nix.conf.
	nixConf := "/etc/nix/nix.conf"
	data, _ := os.ReadFile(nixConf)
	if strings.Contains(string(data), "experimental-features") {
		return nil
	}

	userConf := os.ExpandEnv("$HOME/.config/nix/nix.conf")
	existing, _ := os.ReadFile(userConf)
	if strings.Contains(string(existing), "experimental-features") {
		return nil
	}

	if err := os.MkdirAll(os.ExpandEnv("$HOME/.config/nix"), 0o755); err != nil {
		return err
	}
	f, err := os.OpenFile(userConf, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = f.WriteString("\nexperimental-features = nix-command flakes\n")
	return err
}

func linkConfig() error {
	home, _ := os.UserHomeDir()
	target := home + "/.config/home-manager"
	source, err := findDotfiles()
	if err != nil {
		return err
	}

	info, err := os.Lstat(target)
	if err == nil {
		// Already a symlink pointing to the right place — nothing to do.
		if info.Mode()&os.ModeSymlink != 0 {
			existing, _ := os.Readlink(target)
			if existing == source {
				return nil
			}
			// Wrong target — remove and re-create.
			if err := os.Remove(target); err != nil {
				return fmt.Errorf("removing old symlink %s: %w", target, err)
			}
		} else {
			// Real directory exists — bail out, don't overwrite user data.
			return fmt.Errorf("%s exists and is not a symlink; move it manually first", target)
		}
	}

	if err := os.MkdirAll(home+"/.config", 0o755); err != nil {
		return err
	}
	return os.Symlink(source, target)
}

func ensureHomeManager() error { // Non-fatal: if home-manager isn't on PATH, applyConfig falls back to `nix run`.
	_, _ = exec.LookPath("home-manager")
	return nil
}

func applyConfig(cfg nixConfig) error {
	dotfiles, err := findDotfiles()
	if err != nil {
		return err
	}
	flakeArg := fmt.Sprintf("%s#%s", dotfiles, cfg.flakeTarget)

	hmPath, err := exec.LookPath("home-manager")
	var cmd *exec.Cmd
	if err == nil {
		cmd = exec.Command(hmPath, "switch", "--flake", flakeArg)
	} else {
		cmd = exec.Command("nix", "run", "nixpkgs#home-manager", "--",
			"switch", "--flake", flakeArg)
	}
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// findDotfiles locates the home-manager flake by walking up from the binary,
// then falls back to well-known paths. Returns an error if not found.
func findDotfiles() (string, error) {
	exe, err := os.Executable()
	if err == nil {
		dir := exe
		for range [10]struct{}{} {
			dir = parentDir(dir)
			if fileExists(dir + "/home-manager/.config/home-manager/flake.nix") {
				return dir + "/home-manager/.config/home-manager", nil
			}
		}
	}

	home, _ := os.UserHomeDir()
	candidates := []string{
		home + "/Dotfiles/home-manager/.config/home-manager",
		home + "/dotfiles/home-manager/.config/home-manager",
		home + "/.config/home-manager",
	}
	for _, c := range candidates {
		if fileExists(c + "/flake.nix") {
			return c, nil
		}
	}
	return "", fmt.Errorf(
		"could not find dotfiles repo; clone it to ~/Dotfiles and re-run",
	)
}

func parentDir(p string) string {
	for i := len(p) - 1; i >= 0; i-- {
		if p[i] == '/' {
			return p[:i]
		}
	}
	return "/"
}

func fileExists(p string) bool {
	_, err := os.Stat(p)
	return err == nil
}

// ── Main ──────────────────────────────────────────────────────────────────────

func main() {
	p := tea.NewProgram(initialModel())

	finalModel, err := p.Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}

	if m, ok := finalModel.(model); ok && m.finalErr != nil {
		os.Exit(1)
	}
}
