# Third-Party Binary Dependencies

This project includes external executable tools that are **not** covered by this repository's MIT License. They retain their original copyrights and licenses, which are detailed below.

Per the terms of the GNU General Public License (GPL) and Lesser General Public License (LGPL), source code links for these dependencies are mandatory and provided below.

---

## 1. 7zr.exe (7-Zip Console) - **Mandatory**

* **Utility:** 7-Zip command-line archiving tool.
* **License:** **GNU Lesser General Public License, Version 2.1 or later (LGPLv2.1+)**
  * *Note: This utility includes code licensed under the BSD 3-clause License, and the UnRAR code is subject to specific licensing restrictions.*
* **Project Homepage:** [https://www.7-zip.org/](https://www.7-zip.org/)
* **Source Code Download:** [https://www.7-zip.org/download.html](https://www.7-zip.org/download.html)

**Usage in this project (Required/Mere Aggregation):**
`7zr.exe` is a **required tool** executed as an **external command-line utility** for core archive handling. It must be present in the repository structure for the project to function correctly. It is **not linked**, embedded, or modified by this project's code.

---

## 2. aria2c.exe - **Optional** (Preferred, with Built-in Fallback)

* **Utility:** Multi-protocol command-line download utility.
* **License:** **GNU General Public License, Version 2.0 or later (GPLv2+)**
* **Official Project Page:** [https://aria2.github.io/](https://aria2.github.io/)
* **Source Repository:** [https://github.com/aria2/aria2](https://github.com/aria2/aria2)

**Usage in this project (Preferred/Mere Aggregation):**
This tool is **optional**. The script attempts to use `aria2c.exe` first for optimized downloading. If the binary is **not found** at runtime, the script will automatically **use a fallback, built-in download method** and continue execution without stopping. It is executed as an external, stand-alone program and is **not linked**, embedded, or modified by this project's code.

---

## ⚠️ Notes on License Compliance

* The **`7zr.exe`** binary is **required** for the project's core archive functionality.
* The **`aria2c.exe`** binary is **optional** and provides an optimized download method with a built-in fallback.
* Both binaries are distributed alongside the project only as **separate, stand-alone tools**.
* The main project code is licensed under the **MIT License**, which applies **only** to this repository’s original code.
* The links above fulfill the GPL/LGPL requirement to provide access to the source code for the dependencies.
