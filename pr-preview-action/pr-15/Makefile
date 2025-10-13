SUBDIRS := stackmon openstack_openapi rust_cli rust_keystone rust_keystone_ose rust_cli_tui_oss_2025 rust_keystone_oss_2025

.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@
