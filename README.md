# Gati Platform 

GATI IS NOW OPEN !! 🎉 🥳

Gati is a FPGA based reconfigurable CNN inference platform developed by team by Vicharak.
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


## Hardware 

Gati Platfrom is currently Supported on the [Vaaman](https://store.vicharak.in/?product=vaaman&post_type=product&name=vaaman&v=13b5bfe96f3e) FPGA SBC Developed By Vicharak.

To generate a bitstream for your target model, follow instructions in [hardware/README.md](./hardware/README.md).

To use this on your Vaaman read this [doc](https://github.com/vicharak-in/Gati/blob/main/docs/NewBoard.md) to setup your vaaman. 

## Supported Models

The list of pre quantized model is available in the release section of the repo . However it is not limited to these models.

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


### Install Dependencies 

**Arch**:
```
sudo pacman -S python3 python-pip pkg-config cmake
```

**Fedora**:
``` 
sudo dnf install python3-devel python-pip cmake
```

**Ubuntu/Debian**:
```
sudo apt install python3-dev python3 python3-pip pkg-config cmake
```

**MacOs**
```
brew install python pkg-config cmake
```
---
### Enter the GATICC directory:

```bash
cd software/gaticc
```

### Create and activate a Python virtual environment:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```


**Install dependencies:**

```bash
./scripts/install_deps.sh
```

**Configure and build:**

```bash
cmake -B build
cmake --build build
sudo cmake --install build
pip install -e .
```

**To Build with debug symbols:**

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
```

**Verify Installation**
```bash
gaticc -h
```
> [!NOTE]
> If you encounter:
>
> ```text
> gaticc: error while loading shared libraries: libprotobuf-lite.so.32: cannot open shared object file: No such file or directory
> ```
>
> Refresh the system library cache:
>
> ```bash
> sudo ldconfig
> ```
>
> Then try running `gaticc -h` again.


## Detailed Documentation


[Documentaion](https://vicharak-in.github.io/gati_platform/)


## Contributing

> [!WARNING]
> README-only pull requests are not accepted in this repository.
>
> Pull requests containing only README updates, formatting changes, wording improvements, typo fixes, or other documentation-only modifications will be closed without review or comment.
>
> Documentation updates are accepted only when they accompany a relevant code, hardware, build system, or platform integration change.


This repository serves as an integration layer for the Gati Platform.

Development of individual components happens in their respective repositories:

* Software development, issues, and pull requests should be submitted to the [GATICC](https://github.com/vicharak-in/gaticc.git) repository.
* Hardware development, issues, and pull requests should be submitted to the corresponding [GATI](https://github.com/vicharak-in/Gati.git) repository.

Please refer to the contribution guidelines of those repositories before opening issues or submitting pull requests.

Unless the issue is specifically related to platform integration, issues and pull requests should not be opened in this repository.


## LICENSE 

The Gati Platform and all its submodule are under this [LICENSE](./LICENSE.md)
