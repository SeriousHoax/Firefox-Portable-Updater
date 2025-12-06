# 🦊 Firefox Portable Updater

A simple, self-contained updater script for automatically installing and updating a portable version of the Firefox web browser for Windows, ensuring user profile and settings are preserved across updates.

---

## ✨ Features

* **Automatic Version Check:** Compares the local installed version of Firefox with the latest official release.
* **Seamless Update:** Replaces the core Firefox program files while safely preserving your existing user profile data.
* **Update Suppression:** Configures Firefox policies and user preferences to explicitly disable automatic updates, ensuring full control and portability.
* **Optimized Download:** Uses the external `aria2c.exe` (if available) for fast, multi-threaded downloads, with a robust built-in fallback method.
* **Convenience:** Creates a dedicated Windows shortcut (`Firefox Portable.lnk`) for easy launching.

---

## 🚀 Usage & Script Versions

This project provides two separate scripts to maximize compatibility and performance on Windows:

| Script File | Requirement | Windows Compatibility | Performance |
| :--- | :--- | :--- | :--- |
| **`Firefox-Portable-Updater.py`** | **Python (Installed)** | Requires Python 3 to be installed and available in the system PATH. | **Slightly Faster** |
| **`Firefox-Portable-Updater.cmd`** | **PowerShell** | Works on any modern Windows version (Windows 10/11 recommended) where PowerShell is available. | Standard |

1. **Download:** Clone or download this repository to your chosen portable location.
2. **Dependencies:** Ensure the required external binaries are located in the `Dependencies` subfolder.
3. **Run:** Execute the version that best suits your environment (e.g., double-click the `.cmd` file for best out-of-the-box compatibility, or run the `.py` script if you have Python installed).

---

## 🛠️ License and Dependencies

This repository is licensed under the **MIT License**.  
The included third-party binaries retain their original licenses; see [`DEPENDENCIES.md`](./DEPENDENCIES.md) for details.

---

## 👨‍💻 Author

**[SeriousHoax](https://github.com/SeriousHoax)**
