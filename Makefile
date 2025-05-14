SUBDIRS := stackmon openstack_openapi rust_cli rust_keystone rust_keystone_ose

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
