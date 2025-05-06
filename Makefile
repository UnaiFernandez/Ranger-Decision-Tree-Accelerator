GHDL=ghdl-gcc

sim_time="3000ns"
OBJ = bin/ram_pkg.o \
      bin/ram.o \
      bin/dt_ctl_pkg.o \
      bin/dt_ctl.o \
      bin/dt_ctl_tb.o

test/sim_dt.ghw: dt_ctl_tb
	@ echo "Simulating..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

dt_ctl_tb: $(OBJ)
	$(GHDL) -e --std=08 --workdir=bin $@

bin/%.o: src/%.vhd
	$(GHDL) -a --std=08 --workdir=bin $<

clean:
	@ rm -f bin/*.o
	@ rm -f bin/*.cf

tree:
	@ echo "Creating new tree..."
	python3 dt_model/src/tree.py
