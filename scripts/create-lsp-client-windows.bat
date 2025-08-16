npx esbuild ../src/index.js --bundle --platform=node --outfile=dist/app.js

echo { "main": "dist/app.js", "output": "sea-prep.blob" } > sea-config.json

node --experimental-sea-config sea-config.json
node -e "require('fs').copyFileSync(process.execPath, 'lsp_client.exe')"

npx postject lsp_client.exe NODE_SEA_BLOB sea-prep.blob --sentinel-fuse NODE_SEA_FUSE_fce680ab2cc467b6e072b8b5df1996b2

move lsp_client.exe ../lsp_client.exe

rmdir /s /q dist
del sea-config.json
del sea-prep.blob
