[![codecov](https://codecov.io/github/Tucker-Adkison/micro-lsp-client/graph/badge.svg?token=MAU1JJAOKG)](https://codecov.io/github/Tucker-Adkison/micro-lsp-client)

# LSP Plugin for Micro Text Editor

A Language Server Protocol (LSP) client plugin for the [micro text editor](https://micro-editor.github.io/) that provides intelligent code completion and language features.

## Features

- **Code Completion**: Intelligent autocompletion with dropdown menu navigation

- **Multiple Language Support**: Configure different language servers for different file types

- **Real-time Communication**: Live communication with language servers as you type

- **Keyboard Navigation**: Use arrow keys to navigate completion suggestions

- **Cross-platform**: Works on macOS, Linux, and Windows

## Installation

To install this plugin, run the following command from your CLI

```bash

$ micro -plugin install lspClient

```

## Configuration

Configure language servers by setting the `lsp.server` option in your micro settings. The format is a comma-separated list of `filetype=servername` pairs.

Example configuration:

Add to your `settings.json`:

```json
{
  "lsp.server": "go=gopls,javascript=typescript-language-server,python=pylsp"
}
```

## Supported Language Servers

The plugin supports any LSP-compliant language server. Popular examples include:

- **Go**: `gopls`

- **JavaScript/TypeScript**: `typescript-language-server`

- **Python**: `pylsp` or `pyright`

- **Java**: `jdtls`

- **Rust**: `rust-analyzer`

- **C/C++**: `clangd`

## Usage

1. Open a file in micro with a configured file type

2. The LSP server will automatically start and connect

3. Type to trigger completion suggestions

4. Use arrow keys (↑/↓) to navigate the completion dropdown

5. Press Enter to accept a completion

## Keyboard Shortcuts

- **↑/↓ Arrow Keys**: Navigate completion suggestions

- **Enter**: Accept selected completion

- **Esc**: Close completion dropdown

## File Structure

- `main.lua` - Main plugin entry point and event handlers

- `completion.lua` - Completion logic and UI management

- `lsp.lua` - LSP protocol communication interface

- `server.lua` - Server process management

- `src/` - Node.js LSP client implementation

## Development

### Prerequisites

- Node.js 18+

- micro text editor

- Language servers for your target languages

### Building from Source

```bash

# Install dependencies

npm  install


# Build executable

npm  run  build


# Make scripts executable (macOS/Linux)

./create-executable.sh

### Debugging

Enable logging by checking the `logs/` directory for error output and LSP communication logs.


### LSP Server Not Starting



1. Verify the language server is installed and in your PATH

2. Check the `lsp.server` configuration format

3. Review logs in the `logs/` directory

4. Ensure the language server supports the LSP specification


## Contributing


1. Fork the repository

2. Create a feature branch

3. Make your changes

4. Test with multiple language servers

5. Submit a pull request



## License



MIT License - see LICENSE file for details.



## Author



Tucker Adkison


## Acknowledgments



- [micro text editor](https://micro-editor.github.io/) community

- [Language Server Protocol](https://microsoft.github.io/language-server-protocol/) specification
```
