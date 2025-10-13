SLIDES_OBJ := rust_keystone_reveal.html
SLIDES_SRC := rust_keystone
#IMAGE_SRCS := webauthn_auth
#IMAGE_OBJS := $(foreach var,$(IMAGE_SRCS),$(var).svg)
TITLE := "OpenStack Keystone in Rust"
DESCRIPTION := "Reworking security of Keystonet"

%.png: %.mmd
	mmdc -i $< -o $@

%.svg: %.mmd
	mmdc -i $< -o $@

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width=1280 -V height=720 -V minScale=0.2 -V maxScale=1 -V theme=sky -V center=false -V revealjs-url=https://unpkg.com/reveal.js@^5.2.0 -V plugins=RevealZoom,RevealNotes,RevealSearch --css style.css --embed-resources --standalone

all: $(IMAGE_OBJS) $(SLIDES_OBJ)
