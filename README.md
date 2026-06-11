# Gati Platform 

Gati is a FPGA based reconfigurable DNN inference platform developed by team by Vicharak.
Reconfigurable in a way that it let's you generate the hardware only necessary for the target model.

Gati Currently supports a plethora of operators which can be arranged accordingly to support a list of models. 

## Repository Structure

```text
gati_platform
├── hardware/
|   └── gati/
|   └── rah_bit/
|   └── src/
├── software/
│   └── gaticc/   
└── README.md
```

* `hardware/` - Hardware design and FPGA-related components. 
* `software/gaticc/` - Compiler, simulator, and runtime for the Gati DNN Accelerator.

## Sub Modules 
Gati Platform contains these submodules

gati - This repo contains all the hardware files for the gati DNN Accelerator.
rah_bit - Rah bit is a custom communication protocol designed by Team at vicharak Gati Platform uses this for FPGA CPU communication. 

gaticc -  Gati Compiler Collection is the software side of Gati which contains all the compilers and runtime for Gati.

For more details in any of these please check them out.


## Hardware 

Gati Platfrom is currently Supported on the [Vaaman](https://store.vicharak.in/?product=vaaman&post_type=product&name=vaaman&v=13b5bfe96f3e) FPGA SBC Developed By Vicharak.


To use this on your Vaamam please Follow the instructions below.

## Clone Repository

This repository uses Git submodules.

Clone with:

```bash
git clone --recursive https://github.com/vicharak-in/gati_platform.git
```

If you already cloned the repository without submodules:

```bash
git submodule update --init --recursive
```

## Build GATICC

Enter the GATICC directory:

```bash
cd software/gaticc
```


Create and activate a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```


Install dependencies:

```bash
./scripts/install_deps.sh
```

Configure and build:

```bash
cmake -B build
cmake --build build
sudo cmake --install build
pip install -e .
```

Build with debug symbols:

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
```

## Verify Installation

```bash
gaticc -h
```

## Detailed Documentation

For complete build instructions, platform-specific dependencies, runtime configuration, examples, and API documentation, see:

```text
software/gaticc/docs
```

or visit the [GATICC](https://github.com/vicharak-in/gaticc.git) repository directly.

## Contributing

This repository serves as an integration layer for the Gati Platform.

Development of individual components happens in their respective repositories:

* Software development, issues, and pull requests should be submitted to the [GATICC](https://github.com/vicharak-in/gaticc.git) repository.
* Hardware development, issues, and pull requests should be submitted to the corresponding [GATI](https://github.com/vicharak-in/Gati.git) repository.

Please refer to the contribution guidelines of those repositories before opening issues or submitting pull requests.

Unless the issue is specifically related to platform integration, issues and pull requests should not be opened in this repository.
