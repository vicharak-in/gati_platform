.. Gati Platform documentation master file

Welcome to Gati Platform Documentation
=======================================

Gati is a complete FPGA-based deep learning inference ecosystem designed to accelerate Convolutional Neural Networks (CNNs) on the Vaaman platform. It combines a high-performance hardware accelerator (**GATI**) with a software toolchain (**GATICC**) that enables users to compile, deploy, simulate, and execute machine-learning models.

The project is designed around a simple workflow:

1. Train or obtain a machine-learning model in ONNX format.
2. Use GATICC to compile and optimize the model.
3. Generate a hardware configuration for the target model.
4. Program the FPGA with the appropriate GATI bitstream.
5. Run accelerated inference on the Vaaman SBC.

By combining FPGA acceleration with a flexible software stack, Gati provides a platform for deploying low-latency and power-efficient neural network inference workloads. The system supports multiple hardware architectures and a growing set of neural network operators, allowing users to execute a wide range of CNN-based models on FPGA hardware.

The ecosystem consists of two major components:

**GATI**
The FPGA hardware accelerator responsible for executing neural network operations. GATI implements the compute engines, memory architecture, and data movement required to perform accelerated CNN inference on the FPGA.

**GATICC**
The accompanying software toolchain that compiles ONNX models, manages deployment, provides simulation capabilities, and exposes a Python API for interacting with the accelerator.

Together, GATI and GATICC provide an end-to-end workflow that takes a machine-learning model from development to FPGA deployment with minimal user effort.

Whether you are evaluating existing neural networks, developing custom CNN architectures, or exploring FPGA-based machine learning acceleration, the Gati ecosystem provides the tools necessary to move from ONNX models to accelerated hardware execution.


.. toctree::
   :maxdepth: 1

   Overview <gati/overview>
   Introduction <gaticc/intro>
   Install <gaticc/install>
   Usage <gaticc/usage>
   Hardware Generation <hardware_overview>
   Gati - The Architecture <gati/gati>
   References <gati/references>
   FAQ <gaticc/faq>
