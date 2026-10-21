SLIDES_OBJ := zero_trust_reveal.html
SLIDES_SRC := zero_trust
IMAGE_SRCS := perimeter target_arch spiffe_mtls dpop authz_check delegation attestation interfaces raft_dataplane roadmap workstreams
IMAGE_OBJS := $(foreach var,$(IMAGE_SRCS),$(var).svg)
TITLE := "Zero-trust: rethinking authn/authz in OpenStack"
DESCRIPTION := "Lessons from rebuilding Keystone in Rust without trusting the network"

all: $(IMAGE_OBJS) $(SLIDES_OBJ)

# SVGs are committed (CI has no mermaid-cli); regenerate with `make images`
%.svg: %.mmd
	mmdc -i $< -o $@ -b transparent

%_reveal.html: %.rst
	pandoc -t revealjs -s $< -o $@ --slide-level=2 -M title=$(TITLE) -M subtitle="How to modernize OpenStack" -M author="Artem Goncharov" -M date="2026-10-19" -V width=1920 -V height=1080 -V minScale=0.2 -V maxScale=2 -V theme=sky -V center=false -V revealjs-url=https://unpkg.com/reveal.js@^5.2.0 -V plugins=RevealZoom,RevealNotes,RevealSearch --css style.css --embed-resources --standalone

images: $(IMAGE_OBJS)

.PHONY: all images

all: $(IMAGE_OBJS) $(SLIDES_OBJ)
