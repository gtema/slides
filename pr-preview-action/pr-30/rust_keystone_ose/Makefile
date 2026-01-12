SLIDES_OBJ := rust_keystone_reveal.html
SLIDES_SRC := rust_keystone
IMAGE_SRCS := api_auth
IMAGE_OBJS := $(foreach var,$(IMAGE_SRCS),$(var).svg)
TITLE := "OpenStack Keystone in Rust"
DESCRIPTION := "Rewrite of Keystone in Rust"

%.png: %.mmd
	mmdc -i $< -o $@

%.svg: %.mmd
	mmdc -i $< -o $@

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width:1200 -V height:800 -V theme:sky -V center:false -V revealjs-url=https://unpkg.com/reveal.js@^5.2.0 -V view:scroll --css style.css --embed-resources --standalone 

all: $(IMAGE_OBJS) $(SLIDES_OBJ)
