GHDL=ghdl-gcc

sim_time="20000ns"
OBJ = bin/ram_pkg.o \
      bin/ram.o \
      bin/fifo_pkg.o \
      bin/fifo.o \
      bin/axis_fifo_pkg.o \
      bin/axis_fifo.o \
      bin/dt_ctl_pkg.o \
      bin/dt_ctl.o \
      bin/dt_accel_pkg.o \
      bin/dt_accel.o \
      bin/configurator_pkg.o \
      bin/configurator.o \
	  bin/general_package.o \
      bin/ranger_pkg.o \
      bin/ranger.o \
	  bin/data_sender_pkg.o \
	  bin/data_sender.o \
      bin/RANGER_MAIN_pkg.o \
      bin/RANGER_MAIN.o \
      bin/RANGER_MAIN_DS_pkg.o \
      bin/RANGER_MAIN_DS.o \
      bin/testbench/dt_accel_tb.o \
      bin/testbench/fifo_tb.o \
      bin/testbench/RANGER_MAIN_tb.o \
      bin/testbench/RANGER_MAIN_DS_tb.o
      #bin/testbench/ranger_tb.o \
      #bin/testbench/sched_tb.o

all: test/sim_dt.ghw

accel: test/sim_dt_accel.ghw

ctl: test/sim_dt.ghw

ranger: test/sim_ranger.ghw

fifo: test/sim_fifo.ghw

main: test/sim_ranger_main.ghw

ds: test/sim_ranger_main_ds.ghw

test/sim_dt.ghw: dt_ctl_tb
	@ echo "Simulating" $< "..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

test/sim_dt_accel.ghw: dt_accel_tb
	@ echo "Simulating" $< "..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

test/sim_ranger.ghw: ranger_tb
	@ echo "Simulating" $< "..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

test/sim_fifo.ghw: fifo_tb
	@ echo "Simulating" $< "..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

test/sim_ranger_main.ghw: ranger_main_tb
	@ echo "Simulating" $< "..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

test/sim_ranger_main_ds.ghw: ranger_main_ds_tb
	@ echo "Simulating" $< "..."
	@ $(GHDL) -r  --std=08 $^ --ieee-asserts=disable-at-0 --wave=$@ --stop-time=${sim_time}
	@ mv $< test
	@ rm *.o

dt_ctl_tb: $(OBJ)
	$(GHDL) -e --std=08 --workdir=bin $@

dt_accel_tb: $(OBJ)
	$(GHDL) -e --std=08 --workdir=bin $@

ranger_tb: $(OBJ)
	$(GHDL) -e --std=08 --workdir=bin $@

fifo_tb: $(OBJ)
	$(GHDL) -e --std=08 --workdir=bin $@

ranger_main_tb: $(OBJ)
	$(GHDL) -e --std=08 --workdir=bin $@

ranger_main_ds_tb: $(OBJ)
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
