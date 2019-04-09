# another-go-installer

Script to install `Golang` and create a basic
[workspace](https://golang.org/doc/code.html#Workspaces).
By default the script takes the latest version in the download
[page](https://golang.org/dl/).

## Features

✔ Detects automatically the Operative System (`mac`, `linux`)

✔ Detects automatically the architecture of your OS (`64`, `32` bits)

❌ Prompts for a github user (to create projects directory inside the workspace)

❌ Installs a specific version

✔ checksum of the downloaded file

## Usage

```bash
another-go-installer <OPTION>
```

### Options

```bash
-i      Installs GoLang
-r      Removes ALL things GoLang related (Not the workspace)
```

Written by [Alexander Caba](https://github.com/cabaalexander)

## See also

My dotfiles: <https://github.com/cabaalexander/dotfiles>

## Inspired by

<https://github.com/canha/golang-tools-install-script>
