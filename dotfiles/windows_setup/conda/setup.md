# Conda Setup on Windows (OS-Friendly & Reliable)

This guide explains how to **install, initialize, and use Conda correctly on Windows** without breaking system PATHs or shells.

---

## 1. Recommended Installation (Windows)

### Option A: Miniconda (Preferred – lightweight)

* Download: [https://docs.conda.io/en/latest/miniconda.html](https://docs.conda.io/en/latest/miniconda.html)
* Choose:

  * **Windows x86_64**
  * Python 3.x (latest)

### Option B: Anaconda (Full distribution)

* Download: [https://www.anaconda.com/products/distribution](https://www.anaconda.com/products/distribution)
* Heavier but includes many packages preinstalled.

✅ **During installation**

* ❌ Do NOT check “Add Anaconda to PATH”
* ✅ Check “Register Anaconda as default Python”

This avoids conflicts with system Python.

---

## 2. Initialize Conda (Required)

Open **Anaconda Prompt** (not PowerShell yet):

```bash
conda init
```

This safely configures Conda for:

* PowerShell
* CMD
* Git Bash (if installed)

Then **restart all terminals**.

---

## 3. Verify Installation

In **PowerShell / CMD / Git Bash**:

```bash
conda --version
```

Expected output:

```
conda 24.x.x
```

If this works, PATH is correctly configured.

---

## 4. Activate a Conda Environment

```bash
conda activate base
```

Or a custom environment:

```bash
conda activate myenv
```

Prompt will change to:

```
(myenv) C:\>
```

---

## 5. Create a New Environment (Best Practice)

```bash
conda create -n dev python=3.11 -y
conda activate dev
```

Install packages:

```bash
conda install numpy pandas
pip install streamlit
```

---

## 6. Conda + PowerShell (Fix if Activation Fails)

If you see:

```
conda : The term 'conda' is not recognized
```

Run **once** in PowerShell (Admin not required):

```powershell
conda init powershell
```

Restart PowerShell.

---

## 7. Manual PATH Setup (Only If Conda Init Fails)

⚠️ Use only as a fallback.

Add to **Environment Variables → User PATH**:

```
C:\Users\<username>\anaconda3
C:\Users\<username>\anaconda3\Scripts
C:\Users\<username>\anaconda3\Library\bin
```

Restart system or terminal.

---

## 8. Recommended Shells (OS-Friendly)

| Shell           | Support      | Notes                    |
| --------------- | ------------ | ------------------------ |
| Anaconda Prompt | ✅ Best       | Zero issues              |
| PowerShell      | ✅ Good       | Use `conda init`         |
| CMD             | ✅ Good       | Simple                   |
| Git Bash        | ⚠️ Partial   | Needs `conda init bash`  |
| WSL             | ❌ Not shared | Install Conda separately |

---

## 9. Best Practices (Production-Safe)

* One Conda env per project
* Never mix global Python + Conda
* Use `requirements.txt` or `environment.yml`
* Prefer `conda` for binaries, `pip` for pure Python
* Avoid running Conda as Administrator

---

## 10. Troubleshooting Quick Fixes

### Reset Conda shell config

```bash
conda init --reverse
conda init
```

### Update Conda

```bash
conda update conda -y
```

### List environments

```bash
conda env list
```

### Remove environment

```bash
conda remove -n myenv --all
```

---

## 11. Optional: environment.yml (Reproducible Setup)

```yaml
name: dev
channels:
  - conda-forge
dependencies:
  - python=3.11
  - numpy
  - pandas
  - pip
  - pip:
      - streamlit
```

Create from file:

```bash
conda env create -f environment.yml
```

---

## 12. Verification Checklist

* `conda --version` works in PowerShell
* `conda activate env` works
* Python version is isolated
* No PATH conflicts
* Reboot not required after setup

