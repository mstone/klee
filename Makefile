# Copyright (c) 2011 Akamai Technologies, Inc.

# Disable pre-existing implicit rules and suffix rules for easier dep debugging.
%.o : %.s
% : RCS/%,v
% : RCS/%
% : %,v
% : s.%
% : SCCS/s.%
.SUFFIXES:
SUFFIXES :=

include config.mk

# Debugging aid

pr-%:
	@echo '$*=$($*)'

# rules

%.ok: $($(@)_PRE) % Makefile
	@{ $* && echo "$* OK"; } || { echo "$* FAIL" && head $*.log && exit 1; }
	@touch $@

%/.dir:
	mkdir -p $(@D)
	touch $@

# declarations
#
PROGRAMS = build/bin/klee

SCRIPTS = tools/ktest-tool/ktest-tool

LIBRARIES = build/lib/libkleeRuntimeIntrinsic.bca build/lib/libkleeRuntimePOSIX.bca

HEADERS = build/usr/include/klee/klee.h

MANPAGES_GZ = $(patsubst build/bin/%,man1/%.1.gz,$(SCRIPTS) $(BINARIES))

MANPAGES_HTML = $(patsubst %.gz,%.html,$(MANPAGES))

DATA =

PKGCONFIGS = build/usr/lib/pkgconfig/$(pkgname).pc

# objects

build/bin/klee_RULE = ELF_rule
build/bin/klee_PRE += build/bin/.dir
build/bin/klee_OBJS = \
	tools/klee/main.o \
	lib/Core.a \
	lib/Basic.a \
	lib/Module.a \
	lib/Expr.a \
	lib/Solver.a \
	stp.a \
	lib/Support.a
$(foreach obj,$(filter %.o,$(build/bin/klee_OBJS)),$(eval $(obj)_DEPS += self $(ELF_PRE)))

lib/Support.a_RULE = A_rule
lib/Support.a_OBJS = $(patsubst %.cpp,%.o,$(shell find lib/Support -name '*.cpp'))
$(foreach obj,$(lib/Support.a_OBJS),$(eval $(obj)_DEPS += self $(A_PRE)))

lib/Core.a_RULE = A_rule
lib/Core.a_OBJS = $(patsubst %.cpp,%.o,$(shell find lib/Core -name '*.cpp'))
$(foreach obj,$(lib/Core.a_OBJS),$(eval $(obj)_DEPS += self $(A_PRE)))

lib/Basic.a_RULE = A_rule
lib/Basic.a_OBJS = $(patsubst %.cpp,%.o,$(shell find lib/Basic -name '*.cpp'))
$(foreach obj,$(lib/Basic.a_OBJS),$(eval $(obj)_DEPS += self $(A_PRE)))

lib/Module.a_RULE = A_rule
lib/Module.a_OBJS = $(patsubst %.cpp,%.o,$(shell find lib/Module -name '*.cpp'))
$(foreach obj,$(lib/Module.a_OBJS),$(eval $(obj)_DEPS += self $(A_PRE)))

lib/Expr.a_RULE = A_rule
lib/Expr.a_OBJS = $(patsubst %.cpp,%.o,$(shell find lib/Expr -name '*.cpp'))
$(foreach obj,$(lib/Expr.a_OBJS),$(eval $(obj)_DEPS += self $(A_PRE)))

lib/Solver.a_RULE = A_rule
lib/Solver.a_OBJS = $(patsubst %.cpp,%.o,$(shell find lib/Solver -name '*.cpp'))
$(foreach obj,$(lib/Solver.a_OBJS),$(eval $(obj)_DEPS += self $(A_PRE)))

stp.a_RULE = A_rule
stp.a_OBJS = $(patsubst %.cpp,%.o,$(shell find stp -name '*.cpp'))
$(foreach obj,$(stp.a_OBJS),$(eval $(obj)_DEPS += self $(A_PRE)))

build/lib/libkleeRuntimeIntrinsic.bca_OBJS = $(patsubst %.c,%.bc,$(shell find runtime/Intrinsic -name '*.c'))
build/lib/libkleeRuntimeIntrinsic.bca_RULE = BCA_rule
build/lib/libkleeRuntimeIntrinsic.bca_PRE += build/lib/.dir
$(foreach obj,$(build/lib/libkleeRuntimeIntrinsic.bca_OBJS),$(eval $(obj)_DEPS += self $(BCA_PRE)))

build/lib/libkleeRuntimePOSIX.bca_OBJS = $(patsubst %.c,%.bc,$(shell find runtime/POSIX -name '*.c'))
build/lib/libkleeRuntimePOSIX.bca_RULE = BCA_rule
build/lib/libkleeRuntimePOSIX.bca_PRE += build/lib/.dir
$(foreach obj,$(build/lib/libkleeRuntimePOSIX.bca_OBJS),$(eval $(obj)_DEPS += self $(BCA_PRE)))

build/usr/lib/pkgconfig/klee.pc: build/usr/lib/pkgconfig/.dir config.mk Makefile
	rm -f $@
	echo "prefix=$(prefix)"                >> $@
	echo 'exec_prefix=$${prefix}'          >> $@
	echo 'includedir=$${prefix}/include'   >> $@
	echo 'libdir=$${exec_prefix}/lib'      >> $@
	echo                                   >> $@
	echo 'Name: klee'                      >> $@
	echo 'Description: The klee library'   >> $@
	echo "Version: $(pkgver)"              >> $@
	echo 'Cflags: -I$${includedir}/klee'   >> $@

build/usr/include/klee/klee.h: include/klee/klee.h build/usr/include/klee/.dir
	cp $< $@

t/help.t.ok: build/bin/klee

t/jpeg.bc_CPPFLAGS = -Iinclude/
t/jpeg.t.ok: build/bin/klee t/jpeg.bc

-include private.mk

# codegen

# FIELD(tgt, src, field)
define FIELD_template
$(1)_$(3) += $(filter-out $($(1)_$(3)),$($(2)_$(3)))
endef

# DEP(tgt, src, dep)
define DEP_template
ifdef $(3)_DEPS
$(foreach dep,$($(3)_DEPS),$(eval $(call DEP_template,$(1),$(2),$(dep))))
endif
$(foreach field,CPPFLAGS CFLAGS CXXFLAGS LDFLAGS PRE OBJS,$(eval $(call FIELD_template,$(2),$(3),$(field))))
$(foreach field,PRE OBJS DEPS LDFLAGS,$(eval $(call FIELD_template,$(1),$(2),$(field))))
endef

# OBJ(prog, obj)
define OBJ_template
$(foreach dep,$($(2)_DEPS),$(eval $(call DEP_template,$(1),$(2),$(dep))))
$(foreach obj,$($(2)_OBJS),$(eval $(call OBJ_template,$(2),$(obj))))
ALL_OBJS += $$($(1)_OBJS)
ALL_BUILT += $$($(1)_OBJS) $(1)
$(eval $(call $($(2)_RULE),$(2)))
endef

# ROOT(prog)
define ROOT_template
$(foreach obj,$($(1)_OBJS),$(eval $(call OBJ_template,$(1),$(obj))))
$(foreach dep,$($(1)_DEPS),$(eval $(call DEP_template,$(1),$(dep))))
$(eval $(call $($(1)_RULE),$(1)))
ALL_OBJS += $$($(1)_OBJS)
ALL_BUILT += $$($(1)_OBJS) $(1)
endef

$(foreach prog,$(PROGRAMS),$(eval $(call ROOT_template,$(prog))))
$(foreach lib,$(LIBRARIES),$(eval $(call ROOT_template,$(lib))))

define MAN_template
man$(1)/%.$(1).gz: docs/man/%.txt
	mkdir -p $$(@D) && $$(pandoc_gz)
man$(1)/%.$(1).html: docs/man/%.txt
	mkdir -p $$(@D) && $$(pandoc_html) || :
endef
$(foreach N,1 2 3 4 5 6 7 8,$(eval $(call MAN_template,$(N))))

# targets

all: $(PROGRAMS) $(LIBRARIES) $(HEADERS) $(SCRIPTS) $(PKGCONFIGS) docs

docs: $(MANPAGES_GZ) $(MANPAGES_HTML)

clean:
	rm -f $(MANPAGES_GZ) $(MANPAGES_HTML) $(patsubst %.a,%.d,$(patsubst %.o,%.d,$(patsubst %.bc,%.d,$(ALL_OBJS)))) $(ALL_BUILT) system.hh.gch
	rm -rf $(patsubst %,man%,1 2 3 4 5 6 7 8)
	find t -name '*.ok' -delete

check: all $(patsubst %,%.ok,$(shell find t -name '*.t'))

install: all
	install -d -m 0755 "$(DESTDIR)$(bindir)"
	for f in $(PROGRAMS) $(SCRIPTS); do \
		install -m 0755 $$f "$(DESTDIR)/$(bindir)/$$(basename $$f)"; \
	done
	install -d -m 0755 "$(DESTDIR)$(libdir)"
	for f in $(LIBRARIES); do \
		install -m 0644 $$f "$(DESTDIR)$(libdir)/$$(basename $$f)"; \
	done
	install -d -m 0755 "$(DESTDIR)$(includedir)"
	for f in $(HEADERS); do \
		install -m 0644 $$f "$(DESTDIR)$(includedir)/$$(basename $$f)"; \
	done
	for p in $(MANPAGES_GZ); do \
		install -d -m 0755 "$(DESTDIR)$(mandir)/$$(dirname $$p)"; \
		install -m 0644 $$p "$(DESTDIR)$(mandir)/$$(dirname $$p)/$$(basename $$p)" ; \
	done
	for p in $(DATA); do \
		install -d "$(DESTDIR)$(datadir)/$(nv)/$$(dirname $$p)"; \
		install -m 0644 $$p "$(DESTDIR)$(datadir)/$(nv)/$$(dirname $$p)" ; \
	done
	install -d "$(DESTDIR)$(pkgconfigdir)";
	for p in $(PKGCONFIGS); do \
		install -m 0644 $$p "$(DESTDIR)$(pkgconfigdir)" ; \
	done

.PHONY: clean install all check lint docs
.DEFAULT_GOAL := all

-include $(patsubst %.a,%.d,$(patsubst %.o,%.d,$(patsubst %.bc,%.d,$(ALL_OBJS))))

# vim: noet sts=4 ts=4 sw=4 :
