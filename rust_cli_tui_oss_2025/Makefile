SLIDES_OBJ := rust_cli_tui_reveal.html
SLIDES_SRC := rust_cli_tui
TITLE := "OpenStack Rust CLI&TUI"
DESCRIPTION := "Rust CLI and TUI for OpenStack"

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width=1280 -V height=720 -V minScale=0.2 -V maxScale=1 -V theme=sky -V center=false -V revealjs-url=https://unpkg.com/reveal.js@^5.2.0 -V plugins=RevealZoom,RevealNotes,RevealSearch --css style.css --embed-resources --standalone

all: $(SLIDES_OBJ)
