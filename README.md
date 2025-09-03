# Floating-Point Divider (HUB Format)

## Overview

This module implements a custom **SRT radix-2 floating-point divider** using a simplified, educational format referred to as **HUB**. The design supports normalized numbers only, and handles key IEEE 754-style special cases like ±zero and ±infinity. The goal is to offer a modular, understandable architecture for floating-point division in digital systems.

The core component (`FPHUB_divider`) takes two inputs in HUB format and returns a correctly computed division, managing alignment, normalization, and special cases through a series of coordinated submodules.

---

## HUB Format

Each operand is composed of:

- 1-bit **sign**.
- E-bit **exponent**.
- M-bit **mantissa**, where the leading 1 is implicit (normalized form).

There are **no subnormals**. Even when the exponent is zero, the implicit one is still present in the mantissa.

---

## Key Features

- **Modular architecture**: The design is split into dedicated, self-contained submodules.
- **Special case support **: Recognizes and handles special cases like ±0 and ±∞.

---

## Submodules

- [`special_cases_detector_div`](#special_cases_detector_div): Classifies each operand (e.g., normal, zero, infinity, one).
- [`special_result_for_divider`](#special_result_for_adder): Produces predefined result when special cases are present.

---

## Result Composition

After computations, the final result is assembled from:
- Sign bit (`res_sign`)
- Normalized exponent (`res_exponent`)
- Most significant bits of the mantissa (`res_mantissa`)

the output is a valid HUB-formatted floating-point number.

---

## Usage

To integrate the divider into your own project:

1. **Instantiate** the top module `FPHUB_divider`, or connect its submodules individually for advanced control.
2. **Provide inputs** `X` and `D` using the custom HUB format: `{sign, exponent, mantissa}`.
3. **Monitor** the `finish` output to detect when the operation has completed.
4. **Read** the output `res`, which will contain the final result in HUB format.

### Parameterization

The divider is **fully parameterizable**:
- You can adjust the number of exponent bits (`E`) and mantissa bits (`M`) via parameters.
- By default, the module uses **E = 8** and **M = 23**, which corresponds to a 32-bit floating-point format (1 + 8 + 23 bits).
- This allows easy scaling of precision for custom applications, embedded systems, or educational experiments.

---


## License

This project is intended for educational and research purposes.
Feel free to adapt it to your own system design work or coursework.
