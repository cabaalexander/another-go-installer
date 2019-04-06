# another-go-installer

Script to install `Golang` and create a basic [workspace](https://golang.org/doc/code.html#Workspaces). By default the script takes the latest version in the download [page](https://golang.org/dl/).

## Features

✔ Detects automatically the Operative System (`mac`, `linux`)

✔ Detects automatically the architecture of your OS (`64`, `32` bits)

❌ Prompts for a github user (to create projects directory inside the workspace)

❌ Installs a specific version

---

## Usage

```bash
another-go-installer <OPTION>
```

### Options

    -i      Installs GoLang
    -r      Remove ALL things GoLang related (Not the workspace)

## Inspired by

<https://github.com/canha/golang-tools-install-script>

---

Written by [Alexander Caba](https://github.com/cabaalexander)

    SEE ALSO
    My dotfiles at: https://github.com/cabaalexander/dotfiles