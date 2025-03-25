SLIDES_OBJ := rust_keystone_reveal.html
SLIDES_SRC := rust_keystone
TITLE := "OpenStack Keystone in Rust"
DESCRIPTION := "Rewrite of Keystone in Rust"

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width:1200 -V height:800 -V theme:sky -V center:false -V revealjs-url=https://unpkg.com/reveal.js@^5.2.0 -V view:scroll --css style.css --embed-resources --standalone 

all: $(SLIDES_OBJ)
