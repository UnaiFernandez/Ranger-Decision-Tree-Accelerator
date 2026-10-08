GHDL=ghdl-gcc

sim_time="40000ns"
OBJ = bin/general_package.o \
			bin/count_votes.o \
			bin/aggregator.o \
			bin/r_aggregator.o \
			bin/ram_pkg.o \
      bin/ram.o \
      bin/axis_fifo_pkg.o \
      bin/axis_fifo.o \
      bin/dt_ctl_pkg.o \
      bin/dt_ctl.o \
      bin/dt_accel_pkg.o \
      bin/dt_accel.o \
      bin/configurator_pkg.o \
      bin/configurator.o \
      bin/ranger_pkg.o \
      bin/ranger.o \
      bin/RANGER_MAIN_pkg.o \
      bin/RANGER_MAIN.o \
      bin/testbench/RANGER_MAIN_tb.o
      #bin/testbench/dt_accel_tb.o \
      #bin/testbench/fifo_tb.o \
      #bin/testbench/ranger_tb.o \
      #bin/testbench/test_tb.o \
      #bin/testbench/test_comb_tb.o \
      #bin/testbench/RANGER_MAIN_tb.o
      #bin/testbench/sched_tb.o

all: test/sim_dt.ghw

main: test/sim_ranger_main.ghw

test/sim_ranger_main.ghw: ranger_main_tb
	@ echo "Simulating" $< "..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

ranger_main_tb: $(OBJ)
	$(GHDL) -e --std=08 --workdir=bin $@

bin/%.o: src/%.vhd
	$(GHDL) -a --std=08 --workdir=bin $<

clean:
	@ rm -f bin/*.o
	@ rm -f bin/testbench/*.o
	@ rm -f bin/*.cf

tree:
	@ echo "Creating new tree..."
	python3 ../dt_model/src/tree.py
