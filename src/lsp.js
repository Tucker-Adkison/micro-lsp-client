import { spawn } from "child_process";
import { getInitializeParams } from "./params.js";
import { convertpathToUri } from "./utils.js";
import { Logger } from "./logger.js";

export class Lsp {
  constructor() {
    this.id = 0;
    this.version = 1;
    this.commandcommand = "";
    this.child = null;
    this.filePath = "";
    this.response = "";
    this.logger = new Logger();

    process.on("exit", (code) => {
      this.logger.error("Exited with code: " + code);

      this.shutdown();
    });

    process.stderr.on("data", (data) => {
      this.logger.error("Stderr called with data: " + data);
    });

    process.stdin.on("data", (data) => {
      const lines = data
        .toString()
        .split("\n")
        .filter((n) => n);

      for (let line of lines) {
        try {
          const res = JSON.parse(line);
          const method = res["method"];
          const params = res["params"];

          switch (method) {
            case "initialize":
              this.initialize(params.lsp, params.rootUri);
              break;
            case "didOpen":
              this.didOpen(params.filePath, params.fileText, params.languageId);
              break;
            case "didChange":
              this.didChange(
                params.filePath,
                params.fileText,
                params.languageId
              );
              break;
            case "completion":
              this.completion(
                parseInt(params.line),
                parseInt(params.character)
              );
              break;
            case "definition":
              this.definition(
                parseInt(params.line),
                parseInt(params.character)
              );
              break;
            case "shutdown":
              this.shutdown();
              break;
            default:
              this.logger.info(
                `Command not found for method: ${method} and params: ${params}`
              );
          }
        } catch (e) {
          this.logger.error("Exception thrown in process stdin " + e.stack);
        }
      }
    });
  }

  sendRequest(id, method, params) {
    this.command = method;

    let bodyJson = {
      jsonrpc: "2.0",
      id: id,
      method: method,
      params: params,
    };

    let body = JSON.stringify(bodyJson);
    let content = `Content-Length: ${body.length}\r\n\r\n${body}`;

    this.child.stdin.write(content);
  }

  isJsonString(str) {
    try {
      JSON.parse(str);
    } catch (e) {
      return false;
    }
    return true;
  }

  handleResponse(data) {
    this.logger.info(`Command: ${this.command}, Data: ${data}`);

    try {
      if (
        this.command === "textDocument/completion" ||
        this.command === "textDocument/definition"
      ) {
        if (data.includes("Content-Length")) {
          const split = data.split("\n");
          this.response = split[2];
        } else {
          this.response = this.response.concat(data);
        }

        if (this.isJsonString(this.response)) {
          let jsonResponse = JSON.parse(this.response);

          if (
            (jsonResponse !== undefined && jsonResponse.result !== undefined) ||
            jsonResponse.result !== null
          ) {
            process.stdout.write(JSON.stringify(jsonResponse.result.items));

            this.response = "";
            this.logger.info(
              "isIncomplete: " + jsonResponse.result.isIncomplete
            );
            this.logger.info(
              `Sent output to stdout for command: ${this.command}`
            );
          } else {
            process.stdout.write(JSON.stringify({}));
          }
        }
      }
    } catch (e) {
      this.logger.error("Exception thrown in handleResponse: " + e.stack);
    }
  }

  didChange(filePath, fileText) {
    this.sendRequest(this.id, "textDocument/didChange", {
      textDocument: {
        uri: convertpathToUri(filePath),
        version: this.version,
      },
      contentChanges: [{ text: fileText }],
    });

    this.filePath = filePath;
    this.version++;
    this.id++;
  }

  didOpen(filePath, fileText, languageId) {
    this.sendRequest(this.id, "textDocument/didOpen", {
      textDocument: {
        uri: convertpathToUri(filePath),
        languageId: languageId,
        version: this.version,
        text: fileText,
      },
    });

    this.filePath = fp;
    this.version++;
    this.id++;
  }

  completion(line, character) {
    this.sendRequest(this.id, "textDocument/completion", {
      textDocument: {
        uri: convertpathToUri(this.filePath),
      },
      position: {
        line: line,
        character: character,
      },
    });

    this.id++;
  }

  definition(line, character) {
    this.sendRequest(this.id, "textDocument/definition", {
      textDocument: {
        uri: convertpathToUri(filePath),
      },
      position: {
        line: line,
        character: character,
      },
    });

    this.id++;
  }

  initialize(lsp, rootUri) {
    const args = [];

    if (lsp === "jdtls") {
      args.push("-data", rootUri);
    }

    this.logger.info(`Starting lsp: ${lsp} with args: ${args}`);

    this.child = spawn(lsp, args);

    this.child.stdout.on("data", (data) =>
      this.handleResponse(data.toString())
    );

    const params = getInitializeParams(rootUri, this.child);

    this.sendRequest("", "initialize", params);
    this.sendRequest("", "initialized", {});
  }

  shutdown() {
    this.sendRequest("", "shutdown", {});
    this.sendRequest("", "exit", {});

    this.logger.info("Shutdown and exited the server");
  }
}
