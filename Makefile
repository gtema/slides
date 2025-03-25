SUBDIRS := stackmon openstack_openapi rust_cli rust_keystone

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
