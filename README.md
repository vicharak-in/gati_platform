# Gati Platform

The Gati Platform repository contains all components required to build and run applications on the Gati CNN Accelerator.

## Repository Structure

```text
gati_platform
├── hardware/
├── software/
│   └── gaticc/
└── README.md
```

* `hardware/` - Hardware design and FPGA-related components.
* `software/gaticc/` - Compiler, simulator, and runtime for the Gati DNN Accelerator.

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
