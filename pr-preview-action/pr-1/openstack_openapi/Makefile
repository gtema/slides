SLIDES_OBJ := openapi_reveal.html
SLIDES_SRC := openapi
TITLE := "OpenStack OpenAPI specs"
DESCRIPTION := "OpenAPI specs for OpenStack"

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ -V width:1200 -V height:800 --standalone -V theme:sky --css style.css --embed-resources --standalone

all: $(SLIDES_OBJ)
