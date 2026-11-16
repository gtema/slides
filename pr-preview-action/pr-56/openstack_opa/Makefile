SLIDES_OBJ := openstack_opa_reveal.html
SLIDES_SRC := openstack_opa
TITLE := "Fine-grained and centralized authorization for OpenStack with Open Policy Agent"
DESCRIPTION := "Integrating OPA with OpenStack"

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width=1920 -V height=1080 -V minScale=0.2 -V maxScale=2 -V theme=sky -V center=false -V revealjs-url=https://unpkg.com/reveal.js@^5.2.0 -V plugins=RevealZoom,RevealNotes,RevealSearch --css style.css --embed-resources --standalone

all: $(SLIDES_OBJ)
