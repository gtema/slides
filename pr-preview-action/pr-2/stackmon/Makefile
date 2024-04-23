SLIDES_OBJ := stackmon_reveal.html
SLIDES_SRC := stackmon
IMAGE_SRCS := overview dataflow rough_design lb
IMAGE_OBJS := $(foreach var,$(IMAGE_SRCS),$(var).svg)
TITLE := "StackMon"
DESCRIPTION := "Observation for OpenStack cloud status"

%.png: %.mmd
	mmdc -i $< -o $@

%.svg: %.mmd
	mmdc -i $< -o $@

#%_marp.html: %.md $(IMAGE_OBJ)
#	marp $< -o $@ --title $(TITLE) --description $(DESCRIPTION) --allow-local-files --html --theme default

%_reveal.html: %.rst $(IMAGE_OBJ)
	pandoc -t revealjs -s $< -o $@ -V width:1200 -V height:800 -V theme:moon --css style.css

all: $(IMAGE_OBJS) $(SLIDES_OBJ)
