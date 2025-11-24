export const getLspArgs = (lsp, rootUri) => {
  const args = [];

  if (lsp === "jdtls") {
    args.push("-data", rootUri);
  }

  return args;
};
