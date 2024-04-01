# another-go-installer

Script to install `Golang` and create a basic
[workspace](https://golang.org/doc/code.html#Workspaces).
By default the script takes the latest version in the download
[page](https://golang.org/dl/).

## Features

✔ Detects automatically the Operative System (`mac`, `linux`)

✔ Detects automatically the architecture of your OS (`64`, `32` bits / `arm`)

❌ Prompts for a github user (to create projects directory inside the workspace)

✔ Installs a specific version

✔ checksum of the downloaded file

## Usage

```bash
another-go-installer [OPTION]
```

### Options

```bash
-i [VERSION]    Installs latest version of GoLang (Or you can pass a version)
-r              Removes ALL things GoLang related (Not the workspace)
-h              Shows the help
-q              Does not add the environment variables to your *rc file
```

