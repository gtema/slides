SLIDES_OBJ := rust_cli_reveal.html
SLIDES_SRC := rust_cli
TITLE := "OpenStack Rust CLI"
DESCRIPTION := "Rust CLI for OpenStack"

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width:1200 -V height:800 --standalone -V theme:sky -V center:false --css style.css --embed-resources --standalone -V revealjs-url=https://unpkg.com/reveal.js@^5.2.0

all: $(SLIDES_OBJ)
