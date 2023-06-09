IMAGE_SRCS := overview dataflow rough_design lb
SLIDES_OBJ := stackmon_marp.html stackmon_reveal.html
SLIDES_SRC := stackmon
IMAGE_OBJS := $(foreach var,$(IMAGE_SRCS),$(var).svg)
TITLE := "StackMon"
DESCRIPTION := "Observation for OpenStack cloud status"

%.png: %.mmd
	mmdc -i $< -o $@

%.svg: %.mmd
	mmdc -i $< -o $@

%_marp.html: %.md
	marp $< -o $@ --title $(TITLE) --description $(DESCRIPTION) --allow-local-files --theme default

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width:1000 -V heigth:500 -V theme:moon --css style.css

all: $(IMAGE_OBJS) $(SLIDES_OBJ)
