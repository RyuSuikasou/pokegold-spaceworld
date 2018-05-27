.PHONY: all compare clean text

.SUFFIXES:
.SUFFIXES: .asm .o .gb .png
.SECONDEXPANSION:

ROMS := pokegold-spaceworld.gb
BASEROM := baserom.gb
OBJS := main.o wram.o shim.o

# Link objects together to build a rom.
all: $(ROMS) compare

tools:
	$(MAKE) -C tools/

define DEP
$1: $2 $$(shell tools/scan_includes $2)
	rgbasm -E -o $$@ $$<
endef

ifeq (,$(filter clean tools,$(MAKECMDGOALS)))
$(info $(shell $(MAKE) -C tools))

$(foreach obj, $(OBJS), $(eval $(call DEP,$(obj),$(obj:.o=.asm))))

endif

shim.asm: shim.sym
	python3 tools/make_shim.py $^ > $@

$(ROMS): $(OBJS)
	rgblink -n $(ROMS:.gb=.sym) -m $(ROMS:.gb=.map) -O $(BASEROM) -o $@ $^
	rgbfix -f  -v -k 01 -l 0x33 -m 0x03 -p 0 -r 3 -t "POKEMON2GOLD" $@

compare: $(ROMS) $(BASEROM)
	cmp $^

# Remove files generated by the build process.
clean:
	rm -rf $(ROMS) $(OBJS) $(ROMS:.gb=.sym) build/*
	find . \( -iname '*.1bpp' -o -iname '*.2bpp' -o -iname '*.pcm' \) -exec rm {} +

%.2bpp: %.png
	rgbgfx -o $@ $<

%.1bpp: %.png
	rgbgfx -d1 -o $@ $<

%.tilemap: %.png
	rgbgfx -t $@ $<
