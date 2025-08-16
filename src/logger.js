import { createWriteStream, mkdirSync } from "fs";
import { join } from "path";

export class Logger {
  constructor() {
    mkdirSync(join(process.cwd(), "logs"), { recursive: true });
  }

  info(d) {
    const logPath = join(process.cwd(), "logs", "info.txt");
    const log_info_file = createWriteStream(logPath, { flags: "a" });
    log_info_file.write(d + "\n");
  }

  error(d) {
    const logPath = join(process.cwd(), "logs", "error.txt");
    const log_error_file = createWriteStream(logPath, { flags: "a" });
    log_error_file.write(d + "\n");
  }
}
