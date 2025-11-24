export class Logger {
  constructor(stdout) {
    this.stdout = stdout;
  }

  info(d) {
    this.stdout.write(
      JSON.stringify({
        info: d,
      }) + "\n"
    );
  }

  error(d) {
    this.stdout.write(
      JSON.stringify({
        error: d,
      }) + "\n"
    );
  }
}
