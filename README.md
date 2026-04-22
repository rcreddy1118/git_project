# MyVCS

A minimal Version Control System written in C.
Implements core Git-like functionality including staging, commits, history tracking, checkout, and diff.

---

## 🔧 Requirements

* GCC
* Make
* OpenSSL development libraries

Install OpenSSL (Ubuntu/Debian):

```bash
sudo apt install libssl-dev
```

---

# 🛠 Build

```bash
make
```

Creates:

```bash
./myvcs
```

---

# 📦 Install (Recommended)

To use `myvcs` inside repositories without `../myvcs`, install it system-wide:

```bash
make install
```

After installation:

```bash
myvcs
```

from any directory.

Uninstall:

```bash
make uninstall
```

---

# 🚀 Commands & What They Do

## `myvcs init <repo_name>`

Creates a new directory and initializes internal version control structure.

Example:

```bash
myvcs init demo
cd demo
```

Creates hidden folder:

```bash
ls -a
```

```
.myvcs
```

---

## `myvcs add <file>`

Stages a file for commit.

What it does:

* Generates SHA-1 hash of file
* Stores file content in `.myvcs/objects/`
* Updates staging file `.myvcs/index`

Example:

```bash
myvcs add a.txt
```

---

## `myvcs commit "message"`

Creates a new commit snapshot.

What it does:

* Reads staged files from index
* Creates commit object in `.myvcs/commits/`
* Links commit to previous commit (parent)
* Updates `.myvcs/refs/heads/master`
* Clears staging area

Example:

```bash
myvcs commit "Initial commit"
```

Check commit storage:

```bash
ls .myvcs/commits
```

---

## `myvcs status`

Shows repository state.

Displays:

* Staged files
* Modified but not staged files
* Untracked files

Example:

```bash
myvcs status
```

---

## `myvcs log`

Displays commit history from latest to oldest.

Shows:

* Commit hash
* Message
* Timestamp

Example:

```bash
myvcs log
```

---

## `myvcs checkout <commit_hash>`

Restores working directory to a specific commit.

What it does:

* Reads commit file
* Restores tracked files from `.myvcs/objects/`
* Updates master reference

Example:

```bash
myvcs checkout 8f3c2a1...
```

---

## `myvcs diff <file>`

Shows differences between:

* Current working file
* Last committed version

Example:

```bash
myvcs diff a.txt
```

---

# 📁 Inspecting Internal Storage

Inside a repository:

```bash
cd .myvcs
ls
```

```
objects/     # Stored file contents (SHA-1 named)
commits/     # Commit metadata
refs/heads/  # Latest commit reference
HEAD         # Current branch pointer
index        # Staging area
```

You can inspect:

```bash
cat refs/heads/master
ls objects
ls commits
```

---

# 📌 Example Workflow

```bash
make
make install

myvcs init demo
cd demo

echo "Hello" > a.txt
myvcs add a.txt
myvcs commit "Add a.txt"

echo "Hello World" > a.txt
myvcs status
myvcs diff a.txt
myvcs log
```

---

# 🏗 Makefile Targets

| Command          | Purpose                 |
| ---------------- | ----------------------- |
| `make`           | Build binary            |
| `make install`   | Install globally        |
| `make uninstall` | Remove installed binary |
| `make clean`     | Remove binary           |
| `make rebuild`   | Clean + rebuild         |
| `make run`       | Build and execute       |

---

# 👨‍💻 Author

**U. Rama charan Reddy**
Indian Institute of Technology Madras (IITM)

---

Minimal. Practical. Systems-focused.
