# RISCV
This projects goal is to create a very simple and not strictly standard conform RISCV32I cpu. Although its simple, its not very fast

## Tests
We use the FOSS tool Verilator to simulate the RISCV and its components. Verilator builds C++ models from the design files,
which are instantiated in a C++ testbench. Each module is instantiated in a test wrapper (tst_\*.v). This is only needed
to define the traces in an initial block. Other than that, only the ports are forwarded.  

We use the stable branch of Verilator. The apt-get downloadable version (3.916-1build1) is not compatible.
The individual modules are checked for correct behavior with assert statements.

To start a test, use the Makefile with argument test_<modulename>  
```bash
cd RISCV
make test_alu
make test_registerfile
make test_pc
make test_riscv
```

The test *test_riscv* uses a memory connected via the Wishbone bus, where commands can be created using [risbuj]_type() constructors.
So you don't have to think where which bit has to go for each command. Alternative you can also convert a hex compiler output to a includable
format with the tool converttoarray.elf. The bus interface consists of an object of the class wischbone.
  
